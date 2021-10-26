{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveFunctor #-}

-- ----------------------------------------------------------------------------
-- | Base LLVM Code Generation module
--
-- Contains functions useful through out the code generator.
--

module LlvmCodeGen.Base (

        LlvmCmmDecl, LlvmBasicBlock,
        LiveGlobalRegs,
        LlvmUnresData, LlvmData, UnresLabel, UnresStatic,

        LlvmVersion, llvmVersionSupported, parseLlvmVersion,
        supportedLlvmVersionLowerBound, supportedLlvmVersionUpperBound,
        llvmVersionStr, llvmVersionList,

        LlvmM,
        runLlvm, liftStream, withClearVars, varLookup, varInsert,
        markStackReg, checkStackReg,
        funLookup, funInsert, getLlvmVer, getDynFlags, getDynFlag, getLlvmPlatform,
        dumpIfSetLlvm, renderLlvm, markUsedVar, getUsedVars,
        ghcInternalFunctions,

        getMetaUniqueId,
        setUniqMeta, getUniqMeta,

        cmmToLlvmType, widthToLlvmFloat, widthToLlvmInt, llvmFunTy,
        llvmFunSig, llvmFunArgs, llvmStdFunAttrs, llvmFunAlign, llvmInfAlign,
        llvmPtrBits, tysToParams, llvmFunSection,

        strCLabel_llvm, strDisplayName_llvm, strProcedureName_llvm,
        getGlobalPtr, generateExternDecls,

        aliasify, llvmDefLabel,

        padLiveArgs, isFPR
    ) where

#include "HsVersions.h"
#include "ghcautoconf.h"

import GhcPrelude

import Llvm
import LlvmCodeGen.Regs
import Panic

import PprCmm ()
import CLabel
import GHC.Platform.Regs ( activeStgRegs, globalRegMaybe )
import DynFlags
import FastString
import Cmm              hiding ( succ )
import CmmUtils (regsOverlap)
import Outputable as Outp
import GHC.Platform
import UniqFM
import Unique
import BufWrite   ( BufHandle )
import UniqSet
import UniqSupply
import ErrUtils
import qualified Stream

import Data.Maybe (fromJust)
import Control.Monad (ap)
import Data.Char (isDigit)
import Data.List (sortBy, groupBy, intercalate)
import Data.Ord (comparing)
import qualified Data.List.NonEmpty as NE

-- ----------------------------------------------------------------------------
-- * Some Data Types
--

type LlvmCmmDecl = GenCmmDecl [LlvmData] (Maybe CmmStatics) (ListGraph LlvmStatement)
type LlvmBasicBlock = GenBasicBlock LlvmStatement

-- | Global registers live on proc entry
type LiveGlobalRegs = [GlobalReg]

-- | Unresolved code.
-- Of the form: (data label, data type, unresolved data)
type LlvmUnresData = (CLabel, Section, LlvmType, [UnresStatic])

-- | Top level LLVM Data (globals and type aliases)
type LlvmData = ([LMGlobal], [LlvmType])

-- | An unresolved Label.
--
-- Labels are unresolved when we haven't yet determined if they are defined in
-- the module we are currently compiling, or an external one.
type UnresLabel  = CmmLit
type UnresStatic = Either UnresLabel LlvmStatic

-- ----------------------------------------------------------------------------
-- * Type translations
--

-- | Translate a basic CmmType to an LlvmType.
cmmToLlvmType :: CmmType -> LlvmType
cmmToLlvmType ty | isVecType ty   = LMVector (vecLength ty) (cmmToLlvmType (vecElemType ty))
                 | isFloatType ty = widthToLlvmFloat $ typeWidth ty
                 | otherwise      = widthToLlvmInt   $ typeWidth ty

-- | Translate a Cmm Float Width to a LlvmType.
widthToLlvmFloat :: Width -> LlvmType
widthToLlvmFloat W32  = LMFloat
widthToLlvmFloat W64  = LMDouble
widthToLlvmFloat W128 = LMFloat128
widthToLlvmFloat w    = panic $ "widthToLlvmFloat: Bad float size: " ++ show w

-- | Translate a Cmm Bit Width to a LlvmType.
widthToLlvmInt :: Width -> LlvmType
widthToLlvmInt w = LMInt $ widthInBits w

-- | GHC Call Convention for LLVM
llvmGhcCC :: DynFlags -> LlvmCallConvention
llvmGhcCC dflags
 | platformUnregisterised (targetPlatform dflags) = CC_Ccc
 | otherwise                                      = CC_Ghc

-- | Llvm Function type for Cmm function
llvmFunTy :: LiveGlobalRegs -> LlvmM LlvmType
llvmFunTy live = return . LMFunction =<< llvmFunSig' live (fsLit "a") ExternallyVisible

-- | Llvm Function signature
llvmFunSig :: LiveGlobalRegs ->  CLabel -> LlvmLinkageType -> LlvmM LlvmFunctionDecl
llvmFunSig live lbl link = do
  lbl' <- strCLabel_llvm lbl
  llvmFunSig' live lbl' link

llvmFunSig' :: LiveGlobalRegs -> LMString -> LlvmLinkageType -> LlvmM LlvmFunctionDecl
llvmFunSig' live lbl link
  = do let toParams x | isPointer x = (x, [NoAlias, NoCapture])
                      | otherwise   = (x, [])
       dflags <- getDynFlags
       return $ LlvmFunctionDecl lbl link (llvmGhcCC dflags) LMVoid FixedArgs
                                 (map (toParams . getVarType) (llvmFunArgs dflags live))
                                 (llvmFunAlign dflags)

-- | Alignment to use for functions
llvmFunAlign :: DynFlags -> LMAlign
llvmFunAlign dflags = Just (wORD_SIZE dflags)

-- | Alignment to use for into tables
llvmInfAlign :: DynFlags -> LMAlign
llvmInfAlign dflags = Just (wORD_SIZE dflags)

-- | Section to use for a function
llvmFunSection :: DynFlags -> LMString -> LMSection
llvmFunSection dflags lbl
    | gopt Opt_SplitSections dflags = Just (concatFS [fsLit ".text.", lbl])
    | otherwise                     = Nothing

-- | A Function's arguments
llvmFunArgs :: DynFlags -> LiveGlobalRegs -> [LlvmVar]
llvmFunArgs dflags live =
    map (lmGlobalRegArg dflags) (filter isPassed allRegs)
    where allRegs = activeStgRegs (targetPlatform dflags)
          paddingRegs = padLiveArgs dflags live
          isLive r = r `elem` alwaysLive
                     || r `elem` live
                     || r `elem` paddingRegs
          isPassed r = not (isFPR r) || isLive r


isFPR :: GlobalReg -> Bool
isFPR (FloatReg _)  = True
isFPR (DoubleReg _) = True
isFPR (XmmReg _)    = True
isFPR (YmmReg _)    = True
isFPR (ZmmReg _)    = True
isFPR _             = False

-- | Return a list of "padding" registers for LLVM function calls.
--
-- When we generate LLVM function signatures, we can't just make any register
-- alive on function entry. Instead, we need to insert fake arguments of the
-- same register class until we are sure that one of them is mapped to the
-- register we want alive. E.g. to ensure that F5 is alive, we may need to
-- insert fake arguments mapped to F1, F2, F3 and F4.
--
-- Invariant: Cmm FPR regs with number "n" maps to real registers with number
-- "n" If the calling convention uses registers in a different order or if the
-- invariant doesn't hold, this code probably won't be correct.
padLiveArgs :: DynFlags -> LiveGlobalRegs -> LiveGlobalRegs
padLiveArgs dflags live =
      if platformUnregisterised platform
        then [] -- not using GHC's register convention for platform.
        else padded
  where
    platform = targetPlatform dflags

    ----------------------------------
    -- handle floating-point registers (FPR)

    fprLive = filter isFPR live  -- real live FPR registers

    -- we group live registers sharing the same classes, i.e. that use the same
    -- set of real registers to be passed. E.g. FloatReg, DoubleReg and XmmReg
    -- all use the same real regs on X86-64 (XMM registers).
    --
    classes         = groupBy sharesClass fprLive
    sharesClass a b = regsOverlap dflags (norm a) (norm b) -- check if mapped to overlapping registers
    norm x          = CmmGlobal ((fpr_ctor x) 1)             -- get the first register of the family

    -- For each class, we just have to fill missing registers numbers. We use
    -- the constructor of the greatest register to build padding registers.
    --
    -- E.g. sortedRs = [   F2,   XMM4, D5]
    --      output   = [D1,   D3]
    padded      = concatMap padClass classes
    padClass rs = go sortedRs [1..]
      where
         sortedRs = sortBy (comparing fpr_num) rs
         maxr     = last sortedRs
         ctor     = fpr_ctor maxr

         go [] _ = []
         go (c1:c2:_) _   -- detect bogus case (see #17920)
            | fpr_num c1 == fpr_num c2
            , Just real <- globalRegMaybe platform c1
            = sorryDoc "LLVM code generator" $
               text "Found two different Cmm registers (" <> ppr c1 <> text "," <> ppr c2 <>
               text ") both alive AND mapped to the same real register: " <> ppr real <>
               text ". This isn't currently supported by the LLVM backend."
         go (c:cs) (f:fs)
            | fpr_num c == f = go cs fs              -- already covered by a real register
            | otherwise      = ctor f : go (c:cs) fs -- add padding register
         go _ _ = undefined -- unreachable

    fpr_ctor :: GlobalReg -> Int -> GlobalReg
    fpr_ctor (FloatReg _)  = FloatReg
    fpr_ctor (DoubleReg _) = DoubleReg
    fpr_ctor (XmmReg _)    = XmmReg
    fpr_ctor (YmmReg _)    = YmmReg
    fpr_ctor (ZmmReg _)    = ZmmReg
    fpr_ctor _ = error "fpr_ctor expected only FPR regs"

    fpr_num :: GlobalReg -> Int
    fpr_num (FloatReg i)  = i
    fpr_num (DoubleReg i) = i
    fpr_num (XmmReg i)    = i
    fpr_num (YmmReg i)    = i
    fpr_num (ZmmReg i)    = i
    fpr_num _ = error "fpr_num expected only FPR regs"


-- | Llvm standard fun attributes
llvmStdFunAttrs :: [LlvmFuncAttr]
llvmStdFunAttrs = [NoUnwind]

-- | Convert a list of types to a list of function parameters
-- (each with no parameter attributes)
tysToParams :: [LlvmType] -> [LlvmParameter]
tysToParams = map (\ty -> (ty, []))

-- | Pointer width
llvmPtrBits :: DynFlags -> Int
llvmPtrBits dflags = widthInBits $ typeWidth $ gcWord dflags

-- ----------------------------------------------------------------------------
-- * Llvm Version
--

newtype LlvmVersion = LlvmVersion { llvmVersionNE :: NE.NonEmpty Int }
  deriving (Eq, Ord)

parseLlvmVersion :: String -> Maybe LlvmVersion
parseLlvmVersion =
    fmap LlvmVersion . NE.nonEmpty . go [] . dropWhile (not . isDigit)
  where
    go vs s
      | null ver_str
      = reverse vs
      | '.' : rest' <- rest
      = go (read ver_str : vs) rest'
      | otherwise
      = reverse (read ver_str : vs)
      where
        (ver_str, rest) = span isDigit s

-- | The (inclusive) lower bound on the LLVM Version that is currently supported.
supportedLlvmVersionLowerBound :: LlvmVersion
supportedLlvmVersionLowerBound = LlvmVersion (sUPPORTED_LLVM_VERSION_MIN NE.:| [])

-- | The (not-inclusive) upper bound  bound on the LLVM Version that is currently supported.
supportedLlvmVersionUpperBound :: LlvmVersion
supportedLlvmVersionUpperBound = LlvmVersion (sUPPORTED_LLVM_VERSION_MAX NE.:| [])

llvmVersionSupported :: LlvmVersion -> Bool
llvmVersionSupported v =
  v >= supportedLlvmVersionLowerBound && v < supportedLlvmVersionUpperBound

llvmVersionStr :: LlvmVersion -> String
llvmVersionStr = intercalate "." . map show . llvmVersionList

llvmVersionList :: LlvmVersion -> [Int]
llvmVersionList = NE.toList . llvmVersionNE

-- ----------------------------------------------------------------------------
-- * Environment Handling
--

data LlvmEnv = LlvmEnv
  { envVersion :: LlvmVersion      -- ^ LLVM version
  , envDynFlags :: DynFlags        -- ^ Dynamic flags
  , envOutput :: BufHandle         -- ^ Output buffer
  , envMask :: !Char               -- ^ Mask for creating unique values
  , envFreshMeta :: MetaId         -- ^ Supply of fresh metadata IDs
  , envUniqMeta :: UniqFM MetaId   -- ^ Global metadata nodes
  , envFunMap :: LlvmEnvMap        -- ^ Global functions so far, with type
  , envAliases :: UniqSet LMString -- ^ Globals that we had to alias, see [Llvm Forward References]
  , envUsedVars :: [LlvmVar]       -- ^ Pointers to be added to llvm.used (see @cmmUsedLlvmGens@)

    -- the following get cleared for every function (see @withClearVars@)
  , envVarMap :: LlvmEnvMap        -- ^ Local variables so far, with type
  , envStackRegs :: [GlobalReg]    -- ^ Non-constant registers (alloca'd in the function prelude)
  }

type LlvmEnvMap = UniqFM LlvmType

-- | The Llvm monad. Wraps @LlvmEnv@ state as well as the @IO@ monad
newtype LlvmM a = LlvmM { runLlvmM :: LlvmEnv -> IO (a, LlvmEnv) }
    deriving (Functor)

instance Applicative LlvmM where
    pure x = LlvmM $ \env -> return (x, env)
    (<*>) = ap

instance Monad LlvmM where
    m >>= f  = LlvmM $ \env -> do (x, env') <- runLlvmM m env
                                  runLlvmM (f x) env'

instance HasDynFlags LlvmM where
    getDynFlags = LlvmM $ \env -> return (envDynFlags env, env)

instance MonadUnique LlvmM where
    getUniqueSupplyM = do
        mask <- getEnv envMask
        liftIO $! mkSplitUniqSupply mask

    getUniqueM = do
        mask <- getEnv envMask
        liftIO $! uniqFromMask mask

-- | Lifting of IO actions. Not exported, as we want to encapsulate IO.
liftIO :: IO a -> LlvmM a
liftIO m = LlvmM $ \env -> do x <- m
                              return (x, env)

-- | Get initial Llvm environment.
runLlvm :: DynFlags -> LlvmVersion -> BufHandle -> LlvmM a -> IO a
runLlvm dflags ver out m = do
    (a, _) <- runLlvmM m env
    return a
  where env = LlvmEnv { envFunMap = emptyUFM
                      , envVarMap = emptyUFM
                      , envStackRegs = []
                      , envUsedVars = []
                      , envAliases = emptyUniqSet
                      , envVersion = ver
                      , envDynFlags = dflags
                      , envOutput = out
                      , envMask = 'n'
                      , envFreshMeta = MetaId 0
                      , envUniqMeta = emptyUFM
                      }

-- | Get environment (internal)
getEnv :: (LlvmEnv -> a) -> LlvmM a
getEnv f = LlvmM (\env -> return (f env, env))

-- | Modify environment (internal)
modifyEnv :: (LlvmEnv -> LlvmEnv) -> LlvmM ()
modifyEnv f = LlvmM (\env -> return ((), f env))

-- | Lift a stream into the LlvmM monad
liftStream :: Stream.Stream IO a x -> Stream.Stream LlvmM a x
liftStream s = Stream.Stream $ do
  r <- liftIO $ Stream.runStream s
  case r of
    Left b        -> return (Left b)
    Right (a, r2) -> return (Right (a, liftStream r2))

-- | Clear variables from the environment for a subcomputation
withClearVars :: LlvmM a -> LlvmM a
withClearVars m = LlvmM $ \env -> do
    (x, env') <- runLlvmM m env { envVarMap = emptyUFM, envStackRegs = [] }
    return (x, env' { envVarMap = emptyUFM, envStackRegs = [] })

-- | Insert variables or functions into the environment.
varInsert, funInsert :: Uniquable key => key -> LlvmType -> LlvmM ()
varInsert s t = modifyEnv $ \env -> env { envVarMap = addToUFM (envVarMap env) s t }
funInsert s t = modifyEnv $ \env -> env { envFunMap = addToUFM (envFunMap env) s t }

-- | Lookup variables or functions in the environment.
varLookup, funLookup :: Uniquable key => key -> LlvmM (Maybe LlvmType)
varLookup s = getEnv (flip lookupUFM s . envVarMap)
funLookup s = getEnv (flip lookupUFM s . envFunMap)

-- | Set a register as allocated on the stack
markStackReg :: GlobalReg -> LlvmM ()
markStackReg r = modifyEnv $ \env -> env { envStackRegs = r : envStackRegs env }

-- | Check whether a register is allocated on the stack
checkStackReg :: GlobalReg -> LlvmM Bool
checkStackReg r = getEnv ((elem r) . envStackRegs)

-- | Allocate a new global unnamed metadata identifier
getMetaUniqueId :: LlvmM MetaId
getMetaUniqueId = LlvmM $ \env ->
    return (envFreshMeta env, env { envFreshMeta = succ $ envFreshMeta env })

-- | Get the LLVM version we are generating code for
getLlvmVer :: LlvmM LlvmVersion
getLlvmVer = getEnv envVersion

-- | Get the platform we are generating code for
getDynFlag :: (DynFlags -> a) -> LlvmM a
getDynFlag f = getEnv (f . envDynFlags)

-- | Get the platform we are generating code for
getLlvmPlatform :: LlvmM Platform
getLlvmPlatform = getDynFlag targetPlatform

-- | Dumps the document if the corresponding flag has been set by the user
dumpIfSetLlvm :: DumpFlag -> String -> Outp.SDoc -> LlvmM ()
dumpIfSetLlvm flag hdr doc = do
  dflags <- getDynFlags
  liftIO $ dumpIfSet_dyn dflags flag hdr doc

-- | Prints the given contents to the output handle
renderLlvm :: Outp.SDoc -> LlvmM ()
renderLlvm sdoc = do

    -- Write to output
    dflags <- getDynFlags
    out <- getEnv envOutput
    liftIO $ Outp.bufLeftRenderSDoc dflags out
               (Outp.mkCodeStyle Outp.CStyle) sdoc

    -- Dump, if requested
    dumpIfSetLlvm Opt_D_dump_llvm "LLVM Code" sdoc
    return ()

-- | Marks a variable as "used"
markUsedVar :: LlvmVar -> LlvmM ()
markUsedVar v = modifyEnv $ \env -> env { envUsedVars = v : envUsedVars env }

-- | Return all variables marked as "used" so far
getUsedVars :: LlvmM [LlvmVar]
getUsedVars = getEnv envUsedVars

-- | Saves that at some point we didn't know the type of the label and
-- generated a reference to a type variable instead
saveAlias :: LMString -> LlvmM ()
saveAlias lbl = modifyEnv $ \env -> env { envAliases = addOneToUniqSet (envAliases env) lbl }

-- | Sets metadata node for a given unique
setUniqMeta :: Unique -> MetaId -> LlvmM ()
setUniqMeta f m = modifyEnv $ \env -> env { envUniqMeta = addToUFM (envUniqMeta env) f m }

-- | Gets metadata node for given unique
getUniqMeta :: Unique -> LlvmM (Maybe MetaId)
getUniqMeta s = getEnv (flip lookupUFM s . envUniqMeta)

-- ----------------------------------------------------------------------------
-- * Internal functions
--

-- | Here we pre-initialise some functions that are used internally by GHC
-- so as to make sure they have the most general type in the case that
-- user code also uses these functions but with a different type than GHC
-- internally. (Main offender is treating return type as 'void' instead of
-- 'void *'). Fixes trac #5486.
ghcInternalFunctions :: LlvmM ()
ghcInternalFunctions = do
    dflags <- getDynFlags
    let w = llvmWord dflags
        cint = LMInt $ widthInBits $ cIntWidth dflags
    mk "memcmp" cint [i8Ptr, i8Ptr, w]
    mk "memcpy" i8Ptr [i8Ptr, i8Ptr, w]
    mk "memmove" i8Ptr [i8Ptr, i8Ptr, w]
    mk "memset" i8Ptr [i8Ptr, w, w]
    mk "newSpark" w [i8Ptr, i8Ptr]
  where
    mk n ret args = do
      let n' = fsLit n
          decl = LlvmFunctionDecl n' ExternallyVisible CC_Ccc ret
                                 FixedArgs (tysToParams args) Nothing
      renderLlvm $ ppLlvmFunctionDecl decl
      funInsert n' (LMFunction decl)

-- ----------------------------------------------------------------------------
-- * Label handling
--

-- | Pretty print a 'CLabel'.
strCLabel_llvm :: CLabel -> LlvmM LMString
strCLabel_llvm lbl = do
    dflags <- getDynFlags
    let sdoc = pprCLabel dflags lbl
        str = Outp.renderWithStyle dflags sdoc (Outp.mkCodeStyle Outp.CStyle)
    return (fsLit str)

strDisplayName_llvm :: CLabel -> LlvmM LMString
strDisplayName_llvm lbl = do
    dflags <- getDynFlags
    let sdoc = pprCLabel dflags lbl
        depth = Outp.PartWay 1
        style = Outp.mkUserStyle dflags Outp.reallyAlwaysQualify depth
        str = Outp.renderWithStyle dflags sdoc style
    return (fsLit (dropInfoSuffix str))

dropInfoSuffix :: String -> String
dropInfoSuffix = go
  where go "_info"        = []
        go "_static_info" = []
        go "_con_info"    = []
        go (x:xs)         = x:go xs
        go []             = []

strProcedureName_llvm :: CLabel -> LlvmM LMString
strProcedureName_llvm lbl = do
    dflags <- getDynFlags
    let sdoc = pprCLabel dflags lbl
        depth = Outp.PartWay 1
        style = Outp.mkUserStyle dflags Outp.neverQualify depth
        str = Outp.renderWithStyle dflags sdoc style
    return (fsLit str)

-- ----------------------------------------------------------------------------
-- * Global variables / forward references
--

-- | Create/get a pointer to a global value. Might return an alias if
-- the value in question hasn't been defined yet. We especially make
-- no guarantees on the type of the returned pointer.
getGlobalPtr :: LMString -> LlvmM LlvmVar
getGlobalPtr llvmLbl = do
  m_ty <- funLookup llvmLbl
  let mkGlbVar lbl ty = LMGlobalVar lbl (LMPointer ty) Private Nothing Nothing
  case m_ty of
    -- Directly reference if we have seen it already
    Just ty -> do
      if llvmLbl `elem` (map fsLit ["newSpark", "memmove", "memcpy", "memcmp", "memset"])
        then return $ mkGlbVar (llvmLbl) ty Global
        else return $ mkGlbVar (llvmDefLabel llvmLbl) ty Global
    -- Otherwise use a forward alias of it
    Nothing -> do
      saveAlias llvmLbl
      return $ mkGlbVar llvmLbl i8 Alias

-- | Derive the definition label. It has an identified
-- structure type.
llvmDefLabel :: LMString -> LMString
llvmDefLabel = (`appendFS` fsLit "$def")

-- | Generate definitions for aliases forward-referenced by @getGlobalPtr@.
--
-- Must be called at a point where we are sure that no new global definitions
-- will be generated anymore!
generateExternDecls :: LlvmM ([LMGlobal], [LlvmType])
generateExternDecls = do
  delayed <- fmap nonDetEltsUniqSet $ getEnv envAliases
  -- This is non-deterministic but we do not
  -- currently support deterministic code-generation.
  -- See Note [Unique Determinism and code generation]
  defss <- flip mapM delayed $ \lbl -> do
    m_ty <- funLookup lbl
    case m_ty of
      -- If we have a definition we've already emitted the proper aliases
      -- when the symbol itself was emitted by @aliasify@
      Just _ -> return []

      -- If we don't have a definition this is an external symbol and we
      -- need to emit a declaration
      Nothing ->
        let var = LMGlobalVar lbl i8Ptr External Nothing Nothing Global
        in return [LMGlobal var Nothing]

  -- Reset forward list
  modifyEnv $ \env -> env { envAliases = emptyUniqSet }
  return (concat defss, [])

-- | Here we take a global variable definition, rename it with a
-- @$def@ suffix, and generate the appropriate alias.
aliasify :: LMGlobal -> LlvmM [LMGlobal]
-- See note [emit-time elimination of static indirections] in CLabel.
-- Here we obtain the indirectee's precise type and introduce
-- fresh aliases to both the precise typed label (lbl$def) and the i8*
-- typed (regular) label of it with the matching new names.
aliasify (LMGlobal (LMGlobalVar lbl ty@LMAlias{} link sect align Alias)
                   (Just orig)) = do
    let defLbl = llvmDefLabel lbl
        LMStaticPointer (LMGlobalVar origLbl _ oLnk Nothing Nothing Alias) = orig
        defOrigLbl = llvmDefLabel origLbl
        orig' = LMStaticPointer (LMGlobalVar origLbl i8Ptr oLnk Nothing Nothing Alias)
    origType <- funLookup origLbl
    let defOrig = LMBitc (LMStaticPointer (LMGlobalVar defOrigLbl
                                           (pLift $ fromJust origType) oLnk
                                           Nothing Nothing Alias))
                         (pLift ty)
    pure [ LMGlobal (LMGlobalVar defLbl ty link sect align Alias) (Just defOrig)
         , LMGlobal (LMGlobalVar lbl i8Ptr link sect align Alias) (Just orig')
         ]
aliasify (LMGlobal var val) = do
    let LMGlobalVar lbl ty link sect align const = var

        defLbl = llvmDefLabel lbl
        defVar = LMGlobalVar defLbl ty Internal sect align const

        defPtrVar = LMGlobalVar defLbl (LMPointer ty) link Nothing Nothing const
        aliasVar = LMGlobalVar lbl i8Ptr link Nothing Nothing Alias
        aliasVal = LMBitc (LMStaticPointer defPtrVar) i8Ptr

    -- we need to mark the $def symbols as used so LLVM doesn't forget which
    -- section they need to go in. This will vanish once we switch away from
    -- mangling sections for TNTC.
    markUsedVar defVar

    return [ LMGlobal defVar val
           , LMGlobal aliasVar (Just aliasVal)
           ]

-- Note [Llvm Forward References]
--
-- The issue here is that LLVM insists on being strongly typed at
-- every corner, so the first time we mention something, we have to
-- settle what type we assign to it. That makes things awkward, as Cmm
-- will often reference things before their definition, and we have no
-- idea what (LLVM) type it is going to be before that point.
--
-- Our work-around is to define "aliases" of a standard type (i8 *) in
-- these kind of situations, which we later tell LLVM to be either
-- references to their actual local definitions (involving a cast) or
-- an external reference. This obviously only works for pointers.
--
-- In particular when we encounter a reference to a symbol in a chunk of
-- C-- there are three possible scenarios,
--
--   1. We have already seen a definition for the referenced symbol. This
--      means we already know its type.
--
--   2. We have not yet seen a definition but we will find one later in this
--      compilation unit. Since we want to be a good consumer of the
--      C-- streamed to us from upstream, we don't know the type of the
--      symbol at the time when we must emit the reference.
--
--   3. We have not yet seen a definition nor will we find one in this
--      compilation unit. In this case the reference refers to an
--      external symbol for which we do not know the type.
--
-- Let's consider case (2) for a moment: say we see a reference to
-- the symbol @fooBar@ for which we have not seen a definition. As we
-- do not know the symbol's type, we assume it is of type @i8*@ and emit
-- the appropriate casts in @getSymbolPtr@. Later on, when we
-- encounter the definition of @fooBar@ we emit it but with a modified
-- name, @fooBar$def@ (which we'll call the definition symbol), to
-- since we have already had to assume that the symbol @fooBar@
-- is of type @i8*@. We then emit @fooBar@ itself as an alias
-- of @fooBar$def@ with appropriate casts. This all happens in
-- @aliasify@.
--
-- Case (3) is quite similar to (2): References are emitted assuming
-- the referenced symbol is of type @i8*@. When we arrive at the end of
-- the compilation unit and realize that the symbol is external, we emit
-- an LLVM @external global@ declaration for the symbol @fooBar@
-- (handled in @generateExternDecls@). This takes advantage of the
-- fact that the aliases produced by @aliasify@ for exported symbols
-- have external linkage and can therefore be used as normal symbols.
--
-- Historical note: As of release 3.5 LLVM does not allow aliases to
-- refer to declarations. This the reason why aliases are produced at the
-- point of definition instead of the point of usage, as was previously
-- done. See #9142 for details.
--
-- Finally, case (1) is trival. As we already have a definition for
-- and therefore know the type of the referenced symbol, we can do
-- away with casting the alias to the desired type in @getSymbolPtr@
-- and instead just emit a reference to the definition symbol directly.
-- This is the @Just@ case in @getSymbolPtr@.
