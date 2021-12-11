module CmmCallConv (
  ParamLocation(..),
  assignArgumentsPos,
  assignStack,
  realArgRegsCover
) where

import GhcPrelude

import CmmExpr
import SMRep
import Cmm (Convention(..))
import PprCmm () -- For Outputable instances

import DynFlags
import GHC.Platform
import Outputable

-- Calculate the 'GlobalReg' or stack locations for function call
-- parameters as used by the Cmm calling convention.

data ParamLocation
  = RegisterParam GlobalReg
  | StackParam ByteOff

instance Outputable ParamLocation where
  ppr (RegisterParam g) = ppr g
  ppr (StackParam p)    = ppr p

-- |
-- Given a list of arguments, and a function that tells their types,
-- return a list showing where each argument is passed
--
assignArgumentsPos :: DynFlags
                   -> ByteOff           -- stack offset to start with
                   -> Convention
                   -> (a -> CmmType)    -- how to get a type from an arg
                   -> [a]               -- args
                   -> (
                        ByteOff              -- bytes of stack args
                      , [(a, ParamLocation)] -- args and locations
                      )

assignArgumentsPos dflags off conv arg_ty reps = (stk_off, assignments)
    where
      regs = case (reps, conv) of
               (_,   NativeNodeCall)   -> getRegsWithNode dflags
               (_,   NativeDirectCall) -> getRegsWithoutNode dflags
               ([_], NativeReturn)     -> allRegs dflags
               (_,   NativeReturn)     -> getRegsWithNode dflags
               -- GC calling convention *must* put values in registers
               (_,   GC)               -> allRegs dflags
               (_,   Slow)             -> nodeOnly
      -- The calling conventions first assign arguments to registers,
      -- then switch to the stack when we first run out of registers
      -- (even if there are still available registers for args of a
      -- different type).  When returning an unboxed tuple, we also
      -- separate the stack arguments by pointerhood.
      (reg_assts, stk_args)  = assign_regs [] reps regs
      (stk_off,   stk_assts) = assignStack dflags off arg_ty stk_args
      assignments = reg_assts ++ stk_assts

      assign_regs assts []     _    = (assts, [])
      assign_regs assts (r:rs) regs | isVecType ty   = vec
                                    | isFloatType ty = float
                                    | otherwise      = int
        where vec = case (w, regs) of
                      (W128, (vs, fs, ds, ls, s:ss))
                          | passVectorInReg W128 dflags -> k (RegisterParam (XmmReg s), (vs, fs, ds, ls, ss))
                      (W256, (vs, fs, ds, ls, s:ss))
                          | passVectorInReg W256 dflags -> k (RegisterParam (YmmReg s), (vs, fs, ds, ls, ss))
                      (W512, (vs, fs, ds, ls, s:ss))
                          | passVectorInReg W512 dflags -> k (RegisterParam (ZmmReg s), (vs, fs, ds, ls, ss))
                      _ -> (assts, (r:rs))
              float = case (w, regs) of
                        (W32, (vs, fs, ds, ls, s:ss))
                            | passFloatInXmm          -> k (RegisterParam (FloatReg s), (vs, fs, ds, ls, ss))
                        (W32, (vs, f:fs, ds, ls, ss))
                            | not passFloatInXmm      -> k (RegisterParam f, (vs, fs, ds, ls, ss))
                        (W64, (vs, fs, ds, ls, s:ss))
                            | passFloatInXmm          -> k (RegisterParam (DoubleReg s), (vs, fs, ds, ls, ss))
                        (W64, (vs, fs, d:ds, ls, ss))
                            | not passFloatInXmm      -> k (RegisterParam d, (vs, fs, ds, ls, ss))
                        _ -> (assts, (r:rs))
              int = case (w, regs) of
                      (W128, _) -> panic "W128 unsupported register type"
                      (_, (v:vs, fs, ds, ls, ss)) | widthInBits w <= widthInBits (wordWidth dflags)
                          -> k (RegisterParam (v gcp), (vs, fs, ds, ls, ss))
                      (_, (vs, fs, ds, l:ls, ss)) | widthInBits w > widthInBits (wordWidth dflags)
                          -> k (RegisterParam l, (vs, fs, ds, ls, ss))
                      _   -> (assts, (r:rs))
              k (asst, regs') = assign_regs ((r, asst) : assts) rs regs'
              ty = arg_ty r
              w  = typeWidth ty
              gcp | isGcPtrType ty = VGcPtr
                  | otherwise      = VNonGcPtr
              passFloatInXmm = passFloatArgsInXmm dflags

passFloatArgsInXmm :: DynFlags -> Bool
passFloatArgsInXmm dflags = case platformArch (targetPlatform dflags) of
                              ArchX86_64 -> True
                              ArchX86    -> False
                              _          -> False

-- We used to spill vector registers to the stack since the LLVM backend didn't
-- support vector registers in its calling convention. However, this has now
-- been fixed. This function remains only as a convenient way to re-enable
-- spilling when debugging code generation.
passVectorInReg :: Width -> DynFlags -> Bool
passVectorInReg _ _ = True

assignStack :: DynFlags -> ByteOff -> (a -> CmmType) -> [a]
            -> (
                 ByteOff              -- bytes of stack args
               , [(a, ParamLocation)] -- args and locations
               )
assignStack dflags offset arg_ty args = assign_stk offset [] (reverse args)
 where
      assign_stk offset assts [] = (offset, assts)
      assign_stk offset assts (r:rs)
        = assign_stk off' ((r, StackParam off') : assts) rs
        where w    = typeWidth (arg_ty r)
              off' = offset + size
              -- Stack arguments always take a whole number of words, we never
              -- pack them unlike constructor fields.
              size = roundUpToWords dflags (widthInBytes w)

-----------------------------------------------------------------------------
-- Local information about the registers available

type AvailRegs = ( [VGcPtr -> GlobalReg]   -- available vanilla regs.
                 , [GlobalReg]   -- floats
                 , [GlobalReg]   -- doubles
                 , [GlobalReg]   -- longs (int64 and word64)
                 , [Int]         -- XMM (floats and doubles)
                 )

-- Vanilla registers can contain pointers, Ints, Chars.
-- Floats and doubles have separate register supplies.
--
-- We take these register supplies from the *real* registers, i.e. those
-- that are guaranteed to map to machine registers.

getRegsWithoutNode, getRegsWithNode :: DynFlags -> AvailRegs
getRegsWithoutNode dflags =
  ( filter (\r -> r VGcPtr /= node) (realVanillaRegs dflags)
  , realFloatRegs dflags
  , realDoubleRegs dflags
  , realLongRegs dflags
  , realXmmRegNos dflags)

-- getRegsWithNode uses R1/node even if it isn't a register
getRegsWithNode dflags =
  ( if null (realVanillaRegs dflags)
    then [VanillaReg 1]
    else realVanillaRegs dflags
  , realFloatRegs dflags
  , realDoubleRegs dflags
  , realLongRegs dflags
  , realXmmRegNos dflags)

allFloatRegs, allDoubleRegs, allLongRegs :: DynFlags -> [GlobalReg]
allVanillaRegs :: DynFlags -> [VGcPtr -> GlobalReg]
allXmmRegs :: DynFlags -> [Int]

allVanillaRegs dflags = map VanillaReg $ regList (mAX_Vanilla_REG dflags)
allFloatRegs   dflags = map FloatReg   $ regList (mAX_Float_REG   dflags)
allDoubleRegs  dflags = map DoubleReg  $ regList (mAX_Double_REG  dflags)
allLongRegs    dflags = map LongReg    $ regList (mAX_Long_REG    dflags)
allXmmRegs     dflags =                  regList (mAX_XMM_REG     dflags)

realFloatRegs, realDoubleRegs, realLongRegs :: DynFlags -> [GlobalReg]
realVanillaRegs :: DynFlags -> [VGcPtr -> GlobalReg]
realXmmRegNos :: DynFlags -> [Int]

realVanillaRegs dflags = map VanillaReg $ regList (mAX_Real_Vanilla_REG dflags)
realFloatRegs   dflags = map FloatReg   $ regList (mAX_Real_Float_REG   dflags)
realDoubleRegs  dflags = map DoubleReg  $ regList (mAX_Real_Double_REG  dflags)
realLongRegs    dflags = map LongReg    $ regList (mAX_Real_Long_REG    dflags)

realXmmRegNos dflags
    | isSse2Enabled dflags = regList (mAX_Real_XMM_REG     dflags)
    | otherwise            = []

regList :: Int -> [Int]
regList n = [1 .. n]

allRegs :: DynFlags -> AvailRegs
allRegs dflags = (allVanillaRegs dflags,
                  allFloatRegs dflags,
                  allDoubleRegs dflags,
                  allLongRegs dflags,
                  allXmmRegs dflags)

nodeOnly :: AvailRegs
nodeOnly = ([VanillaReg 1], [], [], [], [])

-- This returns the set of global registers that *cover* the machine registers
-- used for argument passing. On platforms where registers can overlap---right
-- now just x86-64, where Float and Double registers overlap---passing this set
-- of registers is guaranteed to preserve the contents of all live registers. We
-- only use this functionality in hand-written C-- code in the RTS.
realArgRegsCover :: DynFlags -> [GlobalReg]
realArgRegsCover dflags
    | passFloatArgsInXmm dflags
    = map ($VGcPtr) (realVanillaRegs dflags) ++
      realLongRegs dflags ++
      realDoubleRegs dflags -- we only need to save the low Double part of XMM registers.
                            -- Moreover, the NCG can't load/store full XMM
                            -- registers for now...

    | otherwise
    = map ($VGcPtr) (realVanillaRegs dflags) ++
      realFloatRegs dflags ++
      realDoubleRegs dflags ++
      realLongRegs dflags
      -- we don't save XMM registers if they are not used for parameter passing
