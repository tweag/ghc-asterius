-- \section[Hooks]{Low level API hooks}

-- NB: this module is SOURCE-imported by DynFlags, and should primarily
--     refer to *types*, rather than *code*

{-# LANGUAGE CPP #-}
{-# LANGUAGE RankNTypes #-}
module Hooks ( Hooks
             , emptyHooks
             , lookupHook
             , getHooked
               -- the hooks:
             , dsForeignsHook
             , tcForeignImportsHook
             , tcForeignExportsHook
             , hscFrontendHook
             , hscCompileCoreExprHook
             , ghcPrimIfaceHook
             , runPhaseHook
             , runMetaHook
             , linkHook
             , runRnSpliceHook
             , getValueSafelyHook
             , createIservProcessHook
             , codeOutputHook
             , startIServHook
             , iservCallHook
             , readIServHook
             , writeIServHook
             , stopIServHook
             ) where

import GhcPrelude

import DynFlags
import PipelineMonad
import HscTypes
import GHC.Hs.Decls
import GHC.Hs.Binds
import GHC.Hs.Expr
import OrdList
import TcRnTypes
import Bag
import RdrName
import Name
import Id
import CoreSyn
import GHCi.RemoteTypes
import SrcLoc
import Type
import System.Process
import BasicTypes
import GHC.Hs.Extension
import Cmm
import GHCi.Message
import Module
import Stream

import Data.Binary
import Data.Maybe
import Type.Reflection (Typeable)

{-
************************************************************************
*                                                                      *
\subsection{Hooks}
*                                                                      *
************************************************************************
-}

-- | Hooks can be used by GHC API clients to replace parts of
--   the compiler pipeline. If a hook is not installed, GHC
--   uses the default built-in behaviour

emptyHooks :: Hooks
emptyHooks = Hooks
  { dsForeignsHook         = Nothing
  , tcForeignImportsHook   = Nothing
  , tcForeignExportsHook   = Nothing
  , hscFrontendHook        = Nothing
  , hscCompileCoreExprHook = Nothing
  , ghcPrimIfaceHook       = Nothing
  , runPhaseHook           = Nothing
  , runMetaHook            = Nothing
  , linkHook               = Nothing
  , runRnSpliceHook        = Nothing
  , getValueSafelyHook     = Nothing
  , createIservProcessHook = Nothing
  , codeOutputHook         = Nothing
  , startIServHook         = Nothing
  , iservCallHook          = Nothing
  , readIServHook          = Nothing
  , writeIServHook         = Nothing
  , stopIServHook          = Nothing
  }

data Hooks = Hooks
  { dsForeignsHook         :: Maybe ([LForeignDecl GhcTc]
                           -> DsM (ForeignStubs, OrdList (Id, CoreExpr)))
  , tcForeignImportsHook   :: Maybe ([LForeignDecl GhcRn]
                          -> TcM ([Id], [LForeignDecl GhcTc], Bag GlobalRdrElt))
  , tcForeignExportsHook   :: Maybe ([LForeignDecl GhcRn]
            -> TcM (LHsBinds GhcTcId, [LForeignDecl GhcTcId], Bag GlobalRdrElt))
  , hscFrontendHook        :: Maybe (ModSummary -> Hsc FrontendResult)
  , hscCompileCoreExprHook ::
               Maybe (HscEnv -> SrcSpan -> CoreExpr -> IO ForeignHValue)
  , ghcPrimIfaceHook       :: Maybe ModIface
  , runPhaseHook           :: Maybe (PhasePlus -> FilePath -> DynFlags
                                         -> CompPipeline (PhasePlus, FilePath))
  , runMetaHook            :: Maybe (MetaHook TcM)
  , linkHook               :: Maybe (GhcLink -> DynFlags -> Bool
                                         -> HomePackageTable -> IO SuccessFlag)
  , runRnSpliceHook        :: Maybe (HsSplice GhcRn -> RnM (HsSplice GhcRn))
  , getValueSafelyHook     :: Maybe (HscEnv -> Name -> Type
                                                          -> IO (Maybe HValue))
  , createIservProcessHook :: Maybe (CreateProcess -> IO ProcessHandle)
  , codeOutputHook :: Maybe (DynFlags -> Module -> FilePath
           -> ModLocation -> ForeignStubs -> [(ForeignSrcLang, FilePath)]
           -> [InstalledUnitId] -> Stream IO RawCmmGroup ()
           -> IO (FilePath, (Bool, Maybe FilePath), [(ForeignSrcLang, FilePath)], ()))
  , startIServHook         :: Maybe (HscEnv -> IO IServ)
  , iservCallHook          :: forall a . (Binary a, Typeable a) => Maybe (HscEnv -> IServ -> Message a -> IO a)
  , readIServHook          :: forall a . (Binary a, Typeable a) => Maybe (HscEnv -> IServ -> IO a)
  , writeIServHook         :: forall a . (Binary a, Typeable a) => Maybe (HscEnv -> IServ -> a -> IO ())
  , stopIServHook          :: Maybe (HscEnv -> IO ())
  }

getHooked :: (Functor f, HasDynFlags f) => (Hooks -> Maybe a) -> a -> f a
getHooked hook def = fmap (lookupHook hook def) getDynFlags

lookupHook :: (Hooks -> Maybe a) -> a -> DynFlags -> a
lookupHook hook def = fromMaybe def . hook . hooks
