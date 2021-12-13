{-# OPTIONS_GHC -w #-}
{-# OPTIONS -XMagicHash -XBangPatterns -XTypeSynonymInstances -XFlexibleInstances -cpp #-}
#if __GLASGOW_HASKELL__ >= 710
{-# OPTIONS_GHC -XPartialTypeSignatures #-}
#endif
{-# LANGUAGE TupleSections #-}

module CmmParse ( parseCmmFile ) where

import GhcPrelude
import qualified Prelude -- for happy-generated code

import GHC.StgToCmm.ExtCode
import CmmCallConv
import GHC.StgToCmm.Prof
import GHC.StgToCmm.Heap
import GHC.StgToCmm.Monad hiding ( getCode, getCodeR, getCodeScoped, emitLabel, emit
                               , emitStore, emitAssign, emitOutOfLine, withUpdFrameOff
                               , getUpdFrameOff )
import qualified GHC.StgToCmm.Monad as F
import GHC.StgToCmm.Utils
import GHC.StgToCmm.Foreign
import GHC.StgToCmm.Expr
import GHC.StgToCmm.Closure
import GHC.StgToCmm.Layout     hiding (ArgRep(..))
import GHC.StgToCmm.Ticky
import GHC.StgToCmm.Bind  ( emitBlackHoleCode, emitUpdateFrame )
import CoreSyn          ( Tickish(SourceNote) )

import CmmOpt
import MkGraph
import Cmm
import CmmUtils
import CmmSwitch        ( mkSwitchTargets )
import CmmInfo
import BlockId
import CmmLex
import CLabel
import SMRep
import Lexer
import CmmMonad

import CostCentre
import ForeignCall
import Module
import GHC.Platform
import Literal
import Unique
import UniqFM
import SrcLoc
import DynFlags
import ErrUtils
import StringBuffer
import FastString
import Panic
import Constants
import Outputable
import BasicTypes
import Bag              ( emptyBag, unitBag )
import Var

import Control.Monad
import Data.Array
import Data.Char        ( ord )
import System.Exit
import Data.Maybe
import qualified Data.Map as M
import qualified Data.ByteString.Char8 as BS8

import TyCon (PrimRep(..))

#include "HsVersions.h"
import qualified Data.Array as Happy_Data_Array
import qualified Data.Bits as Bits
import qualified GHC.Exts as Happy_GHC_Exts
import Control.Applicative(Applicative(..))
import Control.Monad (ap)

-- parser produced by Happy Version 1.19.12

newtype HappyAbsSyn  = HappyAbsSyn HappyAny
#if __GLASGOW_HASKELL__ >= 607
type HappyAny = Happy_GHC_Exts.Any
#else
type HappyAny = forall a . a
#endif
newtype HappyWrap4 = HappyWrap4 (CmmParse ())
happyIn4 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn4 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap4 x)
{-# INLINE happyIn4 #-}
happyOut4 :: (HappyAbsSyn ) -> HappyWrap4
happyOut4 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut4 #-}
newtype HappyWrap5 = HappyWrap5 (CmmParse ())
happyIn5 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn5 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap5 x)
{-# INLINE happyIn5 #-}
happyOut5 :: (HappyAbsSyn ) -> HappyWrap5
happyOut5 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut5 #-}
newtype HappyWrap6 = HappyWrap6 (CmmParse ())
happyIn6 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn6 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap6 x)
{-# INLINE happyIn6 #-}
happyOut6 :: (HappyAbsSyn ) -> HappyWrap6
happyOut6 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut6 #-}
newtype HappyWrap7 = HappyWrap7 (CmmParse CLabel)
happyIn7 :: (CmmParse CLabel) -> (HappyAbsSyn )
happyIn7 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap7 x)
{-# INLINE happyIn7 #-}
happyOut7 :: (HappyAbsSyn ) -> HappyWrap7
happyOut7 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut7 #-}
newtype HappyWrap8 = HappyWrap8 ([CmmParse [CmmStatic]])
happyIn8 :: ([CmmParse [CmmStatic]]) -> (HappyAbsSyn )
happyIn8 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap8 x)
{-# INLINE happyIn8 #-}
happyOut8 :: (HappyAbsSyn ) -> HappyWrap8
happyOut8 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut8 #-}
newtype HappyWrap9 = HappyWrap9 (CmmParse [CmmStatic])
happyIn9 :: (CmmParse [CmmStatic]) -> (HappyAbsSyn )
happyIn9 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap9 x)
{-# INLINE happyIn9 #-}
happyOut9 :: (HappyAbsSyn ) -> HappyWrap9
happyOut9 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut9 #-}
newtype HappyWrap10 = HappyWrap10 ([CmmParse CmmExpr])
happyIn10 :: ([CmmParse CmmExpr]) -> (HappyAbsSyn )
happyIn10 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap10 x)
{-# INLINE happyIn10 #-}
happyOut10 :: (HappyAbsSyn ) -> HappyWrap10
happyOut10 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut10 #-}
newtype HappyWrap11 = HappyWrap11 (CmmParse ())
happyIn11 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn11 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap11 x)
{-# INLINE happyIn11 #-}
happyOut11 :: (HappyAbsSyn ) -> HappyWrap11
happyOut11 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut11 #-}
newtype HappyWrap12 = HappyWrap12 (Convention)
happyIn12 :: (Convention) -> (HappyAbsSyn )
happyIn12 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap12 x)
{-# INLINE happyIn12 #-}
happyOut12 :: (HappyAbsSyn ) -> HappyWrap12
happyOut12 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut12 #-}
newtype HappyWrap13 = HappyWrap13 (CmmParse ())
happyIn13 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn13 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap13 x)
{-# INLINE happyIn13 #-}
happyOut13 :: (HappyAbsSyn ) -> HappyWrap13
happyOut13 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut13 #-}
newtype HappyWrap14 = HappyWrap14 (CmmParse (CLabel, Maybe CmmInfoTable, [LocalReg]))
happyIn14 :: (CmmParse (CLabel, Maybe CmmInfoTable, [LocalReg])) -> (HappyAbsSyn )
happyIn14 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap14 x)
{-# INLINE happyIn14 #-}
happyOut14 :: (HappyAbsSyn ) -> HappyWrap14
happyOut14 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut14 #-}
newtype HappyWrap15 = HappyWrap15 (CmmParse ())
happyIn15 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn15 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap15 x)
{-# INLINE happyIn15 #-}
happyOut15 :: (HappyAbsSyn ) -> HappyWrap15
happyOut15 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut15 #-}
newtype HappyWrap16 = HappyWrap16 (CmmParse ())
happyIn16 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn16 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap16 x)
{-# INLINE happyIn16 #-}
happyOut16 :: (HappyAbsSyn ) -> HappyWrap16
happyOut16 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut16 #-}
newtype HappyWrap17 = HappyWrap17 ([(FastString, CLabel)])
happyIn17 :: ([(FastString, CLabel)]) -> (HappyAbsSyn )
happyIn17 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap17 x)
{-# INLINE happyIn17 #-}
happyOut17 :: (HappyAbsSyn ) -> HappyWrap17
happyOut17 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut17 #-}
newtype HappyWrap18 = HappyWrap18 ((FastString,  CLabel))
happyIn18 :: ((FastString,  CLabel)) -> (HappyAbsSyn )
happyIn18 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap18 x)
{-# INLINE happyIn18 #-}
happyOut18 :: (HappyAbsSyn ) -> HappyWrap18
happyOut18 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut18 #-}
newtype HappyWrap19 = HappyWrap19 ([FastString])
happyIn19 :: ([FastString]) -> (HappyAbsSyn )
happyIn19 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap19 x)
{-# INLINE happyIn19 #-}
happyOut19 :: (HappyAbsSyn ) -> HappyWrap19
happyOut19 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut19 #-}
newtype HappyWrap20 = HappyWrap20 (CmmParse ())
happyIn20 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn20 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap20 x)
{-# INLINE happyIn20 #-}
happyOut20 :: (HappyAbsSyn ) -> HappyWrap20
happyOut20 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut20 #-}
newtype HappyWrap21 = HappyWrap21 (CmmParse [(GlobalReg, Maybe CmmExpr)])
happyIn21 :: (CmmParse [(GlobalReg, Maybe CmmExpr)]) -> (HappyAbsSyn )
happyIn21 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap21 x)
{-# INLINE happyIn21 #-}
happyOut21 :: (HappyAbsSyn ) -> HappyWrap21
happyOut21 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut21 #-}
newtype HappyWrap22 = HappyWrap22 (CmmParse (Maybe CmmExpr))
happyIn22 :: (CmmParse (Maybe CmmExpr)) -> (HappyAbsSyn )
happyIn22 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap22 x)
{-# INLINE happyIn22 #-}
happyOut22 :: (HappyAbsSyn ) -> HappyWrap22
happyOut22 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut22 #-}
newtype HappyWrap23 = HappyWrap23 (CmmParse CmmExpr)
happyIn23 :: (CmmParse CmmExpr) -> (HappyAbsSyn )
happyIn23 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap23 x)
{-# INLINE happyIn23 #-}
happyOut23 :: (HappyAbsSyn ) -> HappyWrap23
happyOut23 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut23 #-}
newtype HappyWrap24 = HappyWrap24 (CmmReturnInfo)
happyIn24 :: (CmmReturnInfo) -> (HappyAbsSyn )
happyIn24 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap24 x)
{-# INLINE happyIn24 #-}
happyOut24 :: (HappyAbsSyn ) -> HappyWrap24
happyOut24 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut24 #-}
newtype HappyWrap25 = HappyWrap25 (CmmParse BoolExpr)
happyIn25 :: (CmmParse BoolExpr) -> (HappyAbsSyn )
happyIn25 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap25 x)
{-# INLINE happyIn25 #-}
happyOut25 :: (HappyAbsSyn ) -> HappyWrap25
happyOut25 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut25 #-}
newtype HappyWrap26 = HappyWrap26 (CmmParse BoolExpr)
happyIn26 :: (CmmParse BoolExpr) -> (HappyAbsSyn )
happyIn26 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap26 x)
{-# INLINE happyIn26 #-}
happyOut26 :: (HappyAbsSyn ) -> HappyWrap26
happyOut26 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut26 #-}
newtype HappyWrap27 = HappyWrap27 (Safety)
happyIn27 :: (Safety) -> (HappyAbsSyn )
happyIn27 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap27 x)
{-# INLINE happyIn27 #-}
happyOut27 :: (HappyAbsSyn ) -> HappyWrap27
happyOut27 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut27 #-}
newtype HappyWrap28 = HappyWrap28 ([GlobalReg])
happyIn28 :: ([GlobalReg]) -> (HappyAbsSyn )
happyIn28 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap28 x)
{-# INLINE happyIn28 #-}
happyOut28 :: (HappyAbsSyn ) -> HappyWrap28
happyOut28 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut28 #-}
newtype HappyWrap29 = HappyWrap29 ([GlobalReg])
happyIn29 :: ([GlobalReg]) -> (HappyAbsSyn )
happyIn29 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap29 x)
{-# INLINE happyIn29 #-}
happyOut29 :: (HappyAbsSyn ) -> HappyWrap29
happyOut29 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut29 #-}
newtype HappyWrap30 = HappyWrap30 (Maybe (Integer,Integer))
happyIn30 :: (Maybe (Integer,Integer)) -> (HappyAbsSyn )
happyIn30 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap30 x)
{-# INLINE happyIn30 #-}
happyOut30 :: (HappyAbsSyn ) -> HappyWrap30
happyOut30 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut30 #-}
newtype HappyWrap31 = HappyWrap31 ([CmmParse ([Integer],Either BlockId (CmmParse ()))])
happyIn31 :: ([CmmParse ([Integer],Either BlockId (CmmParse ()))]) -> (HappyAbsSyn )
happyIn31 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap31 x)
{-# INLINE happyIn31 #-}
happyOut31 :: (HappyAbsSyn ) -> HappyWrap31
happyOut31 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut31 #-}
newtype HappyWrap32 = HappyWrap32 (CmmParse ([Integer],Either BlockId (CmmParse ())))
happyIn32 :: (CmmParse ([Integer],Either BlockId (CmmParse ()))) -> (HappyAbsSyn )
happyIn32 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap32 x)
{-# INLINE happyIn32 #-}
happyOut32 :: (HappyAbsSyn ) -> HappyWrap32
happyOut32 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut32 #-}
newtype HappyWrap33 = HappyWrap33 (CmmParse (Either BlockId (CmmParse ())))
happyIn33 :: (CmmParse (Either BlockId (CmmParse ()))) -> (HappyAbsSyn )
happyIn33 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap33 x)
{-# INLINE happyIn33 #-}
happyOut33 :: (HappyAbsSyn ) -> HappyWrap33
happyOut33 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut33 #-}
newtype HappyWrap34 = HappyWrap34 ([Integer])
happyIn34 :: ([Integer]) -> (HappyAbsSyn )
happyIn34 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap34 x)
{-# INLINE happyIn34 #-}
happyOut34 :: (HappyAbsSyn ) -> HappyWrap34
happyOut34 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut34 #-}
newtype HappyWrap35 = HappyWrap35 (Maybe (CmmParse ()))
happyIn35 :: (Maybe (CmmParse ())) -> (HappyAbsSyn )
happyIn35 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap35 x)
{-# INLINE happyIn35 #-}
happyOut35 :: (HappyAbsSyn ) -> HappyWrap35
happyOut35 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut35 #-}
newtype HappyWrap36 = HappyWrap36 (CmmParse ())
happyIn36 :: (CmmParse ()) -> (HappyAbsSyn )
happyIn36 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap36 x)
{-# INLINE happyIn36 #-}
happyOut36 :: (HappyAbsSyn ) -> HappyWrap36
happyOut36 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut36 #-}
newtype HappyWrap37 = HappyWrap37 (Maybe Bool)
happyIn37 :: (Maybe Bool) -> (HappyAbsSyn )
happyIn37 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap37 x)
{-# INLINE happyIn37 #-}
happyOut37 :: (HappyAbsSyn ) -> HappyWrap37
happyOut37 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut37 #-}
newtype HappyWrap38 = HappyWrap38 (CmmParse CmmExpr)
happyIn38 :: (CmmParse CmmExpr) -> (HappyAbsSyn )
happyIn38 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap38 x)
{-# INLINE happyIn38 #-}
happyOut38 :: (HappyAbsSyn ) -> HappyWrap38
happyOut38 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut38 #-}
newtype HappyWrap39 = HappyWrap39 (CmmParse CmmExpr)
happyIn39 :: (CmmParse CmmExpr) -> (HappyAbsSyn )
happyIn39 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap39 x)
{-# INLINE happyIn39 #-}
happyOut39 :: (HappyAbsSyn ) -> HappyWrap39
happyOut39 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut39 #-}
newtype HappyWrap40 = HappyWrap40 (CmmType)
happyIn40 :: (CmmType) -> (HappyAbsSyn )
happyIn40 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap40 x)
{-# INLINE happyIn40 #-}
happyOut40 :: (HappyAbsSyn ) -> HappyWrap40
happyOut40 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut40 #-}
newtype HappyWrap41 = HappyWrap41 ([CmmParse (CmmExpr, ForeignHint)])
happyIn41 :: ([CmmParse (CmmExpr, ForeignHint)]) -> (HappyAbsSyn )
happyIn41 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap41 x)
{-# INLINE happyIn41 #-}
happyOut41 :: (HappyAbsSyn ) -> HappyWrap41
happyOut41 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut41 #-}
newtype HappyWrap42 = HappyWrap42 ([CmmParse (CmmExpr, ForeignHint)])
happyIn42 :: ([CmmParse (CmmExpr, ForeignHint)]) -> (HappyAbsSyn )
happyIn42 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap42 x)
{-# INLINE happyIn42 #-}
happyOut42 :: (HappyAbsSyn ) -> HappyWrap42
happyOut42 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut42 #-}
newtype HappyWrap43 = HappyWrap43 (CmmParse (CmmExpr, ForeignHint))
happyIn43 :: (CmmParse (CmmExpr, ForeignHint)) -> (HappyAbsSyn )
happyIn43 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap43 x)
{-# INLINE happyIn43 #-}
happyOut43 :: (HappyAbsSyn ) -> HappyWrap43
happyOut43 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut43 #-}
newtype HappyWrap44 = HappyWrap44 ([CmmParse CmmExpr])
happyIn44 :: ([CmmParse CmmExpr]) -> (HappyAbsSyn )
happyIn44 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap44 x)
{-# INLINE happyIn44 #-}
happyOut44 :: (HappyAbsSyn ) -> HappyWrap44
happyOut44 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut44 #-}
newtype HappyWrap45 = HappyWrap45 ([CmmParse CmmExpr])
happyIn45 :: ([CmmParse CmmExpr]) -> (HappyAbsSyn )
happyIn45 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap45 x)
{-# INLINE happyIn45 #-}
happyOut45 :: (HappyAbsSyn ) -> HappyWrap45
happyOut45 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut45 #-}
newtype HappyWrap46 = HappyWrap46 (CmmParse CmmExpr)
happyIn46 :: (CmmParse CmmExpr) -> (HappyAbsSyn )
happyIn46 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap46 x)
{-# INLINE happyIn46 #-}
happyOut46 :: (HappyAbsSyn ) -> HappyWrap46
happyOut46 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut46 #-}
newtype HappyWrap47 = HappyWrap47 ([CmmParse (LocalReg, ForeignHint)])
happyIn47 :: ([CmmParse (LocalReg, ForeignHint)]) -> (HappyAbsSyn )
happyIn47 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap47 x)
{-# INLINE happyIn47 #-}
happyOut47 :: (HappyAbsSyn ) -> HappyWrap47
happyOut47 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut47 #-}
newtype HappyWrap48 = HappyWrap48 ([CmmParse (LocalReg, ForeignHint)])
happyIn48 :: ([CmmParse (LocalReg, ForeignHint)]) -> (HappyAbsSyn )
happyIn48 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap48 x)
{-# INLINE happyIn48 #-}
happyOut48 :: (HappyAbsSyn ) -> HappyWrap48
happyOut48 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut48 #-}
newtype HappyWrap49 = HappyWrap49 (CmmParse (LocalReg, ForeignHint))
happyIn49 :: (CmmParse (LocalReg, ForeignHint)) -> (HappyAbsSyn )
happyIn49 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap49 x)
{-# INLINE happyIn49 #-}
happyOut49 :: (HappyAbsSyn ) -> HappyWrap49
happyOut49 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut49 #-}
newtype HappyWrap50 = HappyWrap50 (CmmParse LocalReg)
happyIn50 :: (CmmParse LocalReg) -> (HappyAbsSyn )
happyIn50 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap50 x)
{-# INLINE happyIn50 #-}
happyOut50 :: (HappyAbsSyn ) -> HappyWrap50
happyOut50 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut50 #-}
newtype HappyWrap51 = HappyWrap51 (CmmParse CmmReg)
happyIn51 :: (CmmParse CmmReg) -> (HappyAbsSyn )
happyIn51 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap51 x)
{-# INLINE happyIn51 #-}
happyOut51 :: (HappyAbsSyn ) -> HappyWrap51
happyOut51 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut51 #-}
newtype HappyWrap52 = HappyWrap52 (Maybe [CmmParse LocalReg])
happyIn52 :: (Maybe [CmmParse LocalReg]) -> (HappyAbsSyn )
happyIn52 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap52 x)
{-# INLINE happyIn52 #-}
happyOut52 :: (HappyAbsSyn ) -> HappyWrap52
happyOut52 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut52 #-}
newtype HappyWrap53 = HappyWrap53 ([CmmParse LocalReg])
happyIn53 :: ([CmmParse LocalReg]) -> (HappyAbsSyn )
happyIn53 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap53 x)
{-# INLINE happyIn53 #-}
happyOut53 :: (HappyAbsSyn ) -> HappyWrap53
happyOut53 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut53 #-}
newtype HappyWrap54 = HappyWrap54 ([CmmParse LocalReg])
happyIn54 :: ([CmmParse LocalReg]) -> (HappyAbsSyn )
happyIn54 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap54 x)
{-# INLINE happyIn54 #-}
happyOut54 :: (HappyAbsSyn ) -> HappyWrap54
happyOut54 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut54 #-}
newtype HappyWrap55 = HappyWrap55 (CmmParse LocalReg)
happyIn55 :: (CmmParse LocalReg) -> (HappyAbsSyn )
happyIn55 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap55 x)
{-# INLINE happyIn55 #-}
happyOut55 :: (HappyAbsSyn ) -> HappyWrap55
happyOut55 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut55 #-}
newtype HappyWrap56 = HappyWrap56 (CmmType)
happyIn56 :: (CmmType) -> (HappyAbsSyn )
happyIn56 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap56 x)
{-# INLINE happyIn56 #-}
happyOut56 :: (HappyAbsSyn ) -> HappyWrap56
happyOut56 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut56 #-}
newtype HappyWrap57 = HappyWrap57 (CmmType)
happyIn57 :: (CmmType) -> (HappyAbsSyn )
happyIn57 x = Happy_GHC_Exts.unsafeCoerce# (HappyWrap57 x)
{-# INLINE happyIn57 #-}
happyOut57 :: (HappyAbsSyn ) -> HappyWrap57
happyOut57 x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOut57 #-}
happyInTok :: (Located CmmToken) -> (HappyAbsSyn )
happyInTok x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyInTok #-}
happyOutTok :: (HappyAbsSyn ) -> (Located CmmToken)
happyOutTok x = Happy_GHC_Exts.unsafeCoerce# x
{-# INLINE happyOutTok #-}


happyExpList :: HappyAddr
happyExpList = HappyA# "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe0\x37\x00\xc1\xff\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\xdf\x00\x04\xff\x0b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x60\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\xf0\x3f\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x84\x00\x00\x00\x00\xd0\x63\xf3\xff\x03\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x08\x00\x00\x00\x00\x3d\x36\xff\x3f\x00\x00\x00\x00\x00\x00\x00\x10\x02\x00\x00\x00\x40\x8f\xcd\xff\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x14\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\xff\x06\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x08\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\xff\x03\x00\x00\x00\x00\x00\x00\x00\x84\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x10\xc0\xff\xf0\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x00\xf2\x3f\xfc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x28\xfc\x0f\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc3\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfc\x0f\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x08\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x02\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x04\xf0\x3f\xfc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\xfc\x0f\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x06\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\xff\xc3\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x32\x20\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x08\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x08\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x7f\xfc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xf0\x3f\xfc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x04\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfc\x1f\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\xff\xc3\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc1\xff\xf0\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\xfc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x30\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x02\x00\x00\x00\x40\x8f\xcd\xff\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\xfc\x03\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xc0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\x3f\x30\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x0f\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x7c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\x3f\x30\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x0f\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfc\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x3f\xc0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc0\x07\x30\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x70\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x88\x0c\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x80\xc8\x00\x00\x00\x00\x00\xc0\xff\x1f\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x21\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x04\x00\x00\x00\x00\x00\xfc\xff\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x32\x00\x00\x00\x00\x00\xf0\xff\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc2\xff\xf0\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\xf0\x3f\xfc\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfc\x0f\x3f\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x22\x03\x00\x00\x00\x00\x00\xff\x7f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x08\x00\x00\x00\x00\x3d\x36\xff\x3f\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x21\x00\x00\x00\x00\xf4\xd8\xfc\xff\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x02\x00\x00\x00\x40\x8f\xcd\xff\x0f\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"#

{-# NOINLINE happyExpListPerState #-}
happyExpListPerState st =
    token_strs_expected
  where token_strs = ["error","%dummy","%start_cmmParse","cmm","cmmtop","cmmdata","data_label","statics","static","lits","cmmproc","maybe_conv","maybe_body","info","body","decl","importNames","importName","names","stmt","unwind_regs","expr_or_unknown","foreignLabel","opt_never_returns","bool_expr","bool_op","safety","vols","globals","maybe_range","arms","arm","arm_body","ints","default","else","cond_likely","expr","expr0","maybe_ty","cmm_hint_exprs0","cmm_hint_exprs","cmm_hint_expr","exprs0","exprs","reg","foreign_results","foreign_formals","foreign_formal","local_lreg","lreg","maybe_formals","formals0","formals","formal","type","typenot8","':'","';'","'{'","'}'","'['","']'","'('","')'","'='","'`'","'~'","'/'","'*'","'%'","'-'","'+'","'&'","'^'","'|'","'>'","'<'","','","'!'","'..'","'::'","'>>'","'<<'","'>='","'<='","'=='","'!='","'&&'","'||'","'True'","'False'","'likely'","'CLOSURE'","'INFO_TABLE'","'INFO_TABLE_RET'","'INFO_TABLE_FUN'","'INFO_TABLE_CONSTR'","'INFO_TABLE_SELECTOR'","'else'","'export'","'section'","'goto'","'if'","'call'","'jump'","'foreign'","'never'","'prim'","'reserve'","'return'","'returns'","'import'","'switch'","'case'","'default'","'push'","'unwind'","'bits8'","'bits16'","'bits32'","'bits64'","'bits128'","'bits256'","'bits512'","'float32'","'float64'","'gcptr'","GLOBALREG","NAME","STRING","INT","FLOAT","%eof"]
        bit_start = st * 134
        bit_end = (st + 1) * 134
        read_bit = readArrayBit happyExpList
        bits = map read_bit [bit_start..bit_end - 1]
        bits_indexed = zip bits [0..133]
        token_strs_expected = concatMap f bits_indexed
        f (False, _) = []
        f (True, nr) = [token_strs !! nr]

happyActOffsets :: HappyAddr
happyActOffsets = HappyA# "\x44\x01\x00\x00\xba\xff\x44\x01\x00\x00\x00\x00\xdf\xff\x00\x00\xcf\xff\x00\x00\x14\x00\x18\x00\x1c\x00\x1f\x00\x2c\x00\x33\x00\xe4\xff\x21\x00\xe0\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x73\x00\x66\x00\x56\x00\x00\x00\x79\x00\xc9\x00\xcc\x00\xf2\x00\xb4\x00\xc6\x00\xc7\x00\xd8\x00\xda\x00\xe2\x00\x1a\x01\x19\x01\x00\x00\x00\x00\x2e\x00\x2f\x04\x00\x00\x18\x01\x1e\x01\x20\x01\x23\x01\x27\x01\x2a\x01\xf8\x00\x00\x00\xf9\x00\x00\x00\x00\x00\xe0\xff\x00\x00\x00\x00\x07\x01\x43\x01\x00\x00\x04\x01\x05\x01\x09\x01\x0a\x01\x0b\x01\x08\x01\x54\x01\x00\x00\x47\x01\x16\x01\x00\x00\x00\x00\x20\x00\x5f\x01\x20\x00\x20\x00\xfa\xff\x5d\x01\x23\x00\x00\x00\x22\x04\x26\x01\x63\x00\x72\x00\x72\x00\x72\x00\x72\x01\x75\x01\x74\x01\x35\x01\x00\x00\x10\x00\x00\x00\x2f\x04\x00\x00\x68\x01\x69\x01\x08\x00\x76\x01\x8e\x01\x92\x01\x00\x00\xa2\x01\x07\x01\xff\xff\xa7\x01\xb2\x01\xb5\x01\x02\x00\x77\x01\x73\x01\xbf\x01\xbc\x01\x00\x00\xd1\x01\x00\x00\x72\x00\x72\x00\x8f\x01\x72\x00\x00\x00\x00\x00\x00\x00\xbe\x01\xbe\x01\x00\x00\x00\x00\x9f\x01\xa0\x01\xa1\x01\x00\x00\x2f\x04\xb4\x01\xf5\x01\x72\x00\x00\x00\x00\x00\x72\x00\xfe\x01\x08\x02\x72\x00\x72\x00\xc7\x01\x72\x00\xab\x02\x16\x02\x63\x02\xfc\xff\x00\x00\xe7\x02\x63\x00\x63\x00\x11\x02\x0c\x02\x06\x02\x00\x00\x17\x02\x00\x00\xd5\x01\x72\x00\x72\x00\xd6\x01\x13\x02\x00\x00\x00\x00\x00\x00\xe3\x01\xe4\x01\xd3\x01\x30\x02\x00\x00\x25\x02\x26\x00\x26\x02\x00\x00\x00\x00\x5e\x00\x2f\x02\x94\x02\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x72\x00\x01\x00\x14\x02\x63\x00\x63\x00\x72\x00\x37\x02\x25\x00\x72\x00\x3b\x00\xbf\x02\x32\x02\x00\x00\x23\x02\xfb\x01\x3e\x02\x4c\x00\x00\x00\x3f\x02\xd3\x02\x46\x02\x33\x02\x49\x02\x3c\x02\x3d\x02\x4b\x02\x00\x00\x2f\x04\x00\x00\x7b\x00\x4d\x02\x00\x00\x94\x02\x72\x00\x19\x02\x00\x00\x4f\x02\x55\x02\x22\x02\x5a\x02\x61\x02\x6b\x02\x66\x02\x77\x02\x70\x02\x4a\x02\x00\x00\x72\x00\x00\x00\x31\x02\x39\x02\x3a\x02\x00\x00\x3b\x02\x00\x00\x00\x00\x7a\x02\x71\x02\xe7\x02\x00\x00\xc5\x00\x58\x02\x48\x02\x92\x02\x72\x00\xc5\x00\x00\x00\x8d\x02\x97\x02\x00\x00\x98\x02\x89\x02\x00\x00\xa2\x02\xcb\x00\x8b\x02\xac\x02\x20\x00\x6c\x02\xfb\x02\xfb\x02\xfb\x02\xfb\x02\x29\x00\x29\x00\xfb\x02\xfb\x02\x66\x01\x34\x04\x44\x04\x7b\x00\x7b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x86\x02\xa3\x02\x00\x00\xba\x02\x00\x00\xbb\x02\x72\x00\x72\x00\x72\x00\x72\x00\x00\x00\xc0\x02\xd7\x00\xc1\x02\x8e\x02\x00\x00\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\xd1\x02\x9d\x02\xb0\x02\xa0\x02\x00\x00\xa4\x02\x00\x00\xe8\x02\xe9\x02\xea\x02\xfd\x02\xf5\x02\x00\x00\x92\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc7\x02\xc9\x02\xc8\x02\xd6\x02\x00\x00\x1c\x03\x11\x03\x00\x00\x24\x03\x28\x03\x00\x00\x00\x00\x72\x00\x00\x00\x00\x00\x22\x03\x23\x03\x01\x03\x7c\x02\xe7\x01\xd3\x00\x2c\x03\x00\x00\x19\x03\x2f\x03\x3c\x03\x72\x00\xf6\x02\x00\x00\x00\x00\x72\x00\x00\x00\x3e\x03\x00\x00\x00\x00\x37\x03\x3f\x03\x00\x00\xf8\x02\x06\x00\x30\x03\x35\x03\x38\x03\x50\x03\x00\x00\x0d\x03\x16\x03\x17\x03\x00\x00\x20\x00\x25\x03\x00\x00\x20\x00\x60\x03\x20\x00\x67\x03\x3d\x03\x00\x00\x00\x00\x00\x00\x78\x03\x45\x03\x7c\x03\x84\x03\x00\x00\x86\x03\x8a\x03\x92\x03\x75\x03\x82\x03\x83\x03\x5a\x03\x40\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x9e\x03\x9f\x03\x00\x00\x00\x00\x00\x00"#

happyGotoOffsets :: HappyAddr
happyGotoOffsets = HappyA# "\xbf\x00\x00\x00\x00\x00\xc3\x00\x00\x00\x00\x00\xa0\x03\x00\x00\x8b\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xa6\x03\x00\x00\xe8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x90\x03\x00\x00\x00\x00\xa9\x03\x69\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xa7\x03\x00\x00\xc0\x03\x00\x00\x00\x00\xf4\x00\x00\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\x00\x00\x00\xf3\x00\xfb\x00\x00\x00\x00\x00\xb5\x03\x00\x00\x4b\x04\x00\x00\x79\x01\x4f\x03\x51\x03\x5d\x03\x00\x00\x9a\x03\x00\x00\xbd\x03\x00\x00\x00\x00\x00\x00\x90\x01\x00\x00\xbc\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe5\x00\x5f\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x6b\x03\x6d\x03\x00\x00\x79\x03\x00\x00\x00\x00\x00\x00\xac\x03\xad\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x65\x01\x00\x00\x00\x00\x7b\x03\x00\x00\x00\x00\x30\x01\x00\x00\x00\x00\x93\x01\x87\x03\x00\x00\xf9\x02\x00\x00\xba\x03\x00\x00\xbb\x03\x00\x00\x00\x00\x7b\x01\x7d\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xb0\x03\x89\x03\x95\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xcc\x03\x00\x00\x00\x00\x00\x00\x00\x00\xe7\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x97\x03\xa3\x03\xa5\x03\xb1\x03\xb3\x03\xbf\x03\xc1\x03\xcd\x03\xcf\x03\xdb\x03\xdd\x03\xe9\x03\xeb\x03\xf7\x03\xf9\x03\x05\x04\x00\x00\x00\x00\x7f\x01\x95\x01\xfc\x02\x00\x00\xc7\x03\x10\x03\xbe\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0\xff\x00\x00\x00\x00\xe4\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xd0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07\x04\x00\x00\x00\x00\x00\x00\xe6\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x13\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe5\x03\xf1\x00\x00\x00\x00\x00\x43\x03\xef\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x27\x03\x51\x00\x13\x04\x15\x04\x00\x00\x00\x00\x00\x00\x00\x00\xe1\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xdc\x03\xfc\x00\xde\x03\x00\x00\xf5\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xec\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x2a\x03\x00\x00\x00\x00\x00\x00\x00\x00\xe8\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x33\x03\xf2\x03\x00\x00\x00\x00\x41\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xec\x03\xfa\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x06\x01\x00\x00\x00\x00\x2c\x01\x00\x00\x33\x01\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"#

happyAdjustOffset :: Happy_GHC_Exts.Int# -> Happy_GHC_Exts.Int#
happyAdjustOffset off = off

happyDefActions :: HappyAddr
happyDefActions = HappyA# "\xfe\xff\x00\x00\x00\x00\xfe\xff\xfb\xff\xfc\xff\xeb\xff\xfa\xff\x00\x00\x5f\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x60\xff\x5e\xff\x5d\xff\x5c\xff\x5b\xff\x5a\xff\x59\xff\x58\xff\x57\xff\x56\xff\xe7\xff\x00\x00\xda\xff\x00\x00\xd8\xff\x00\x00\x00\x00\x00\x00\xd5\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x68\xff\xea\xff\xfd\xff\x00\x00\x66\xff\xdd\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xdb\xff\x00\x00\xd6\xff\xd7\xff\x00\x00\xdc\xff\xd9\xff\xf6\xff\x00\x00\xd4\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x65\xff\x63\xff\x00\x00\xec\xff\xe9\xff\xe0\xff\x00\x00\xe0\xff\xe0\xff\x00\x00\x00\x00\x00\x00\xd3\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xaa\xff\x00\x00\x00\x00\x69\xff\x6a\xff\x61\xff\x64\xff\x67\xff\xee\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf7\xff\x00\x00\xf6\xff\x00\x00\x5f\xff\x00\x00\x60\xff\x00\x00\x00\x00\x00\x00\x00\x00\x88\xff\x84\xff\x00\x00\xf3\xff\x00\x00\x00\x00\x00\x00\x00\x00\x73\xff\x74\xff\x85\xff\x80\xff\x80\xff\xf5\xff\xf8\xff\x00\x00\x00\x00\x00\x00\xe2\xff\x66\xff\x00\x00\x00\x00\x00\x00\x62\xff\xd2\xff\x78\xff\x00\x00\x00\x00\x78\xff\x00\x00\x00\x00\x78\xff\x00\x00\x00\x00\x00\x00\x9c\xff\xb8\xff\xb7\xff\x00\x00\x00\x00\x00\x00\x00\x00\x70\xff\x6d\xff\x00\x00\x6b\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xde\xff\xdf\xff\xe8\xff\x00\x00\x00\x00\x00\x00\x00\x00\x6c\xff\x00\x00\x6f\xff\x00\x00\xcb\xff\xb4\xff\x00\x00\xb8\xff\xb7\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x78\xff\x00\x00\x00\x00\x78\xff\x00\x00\x76\xff\x00\x00\x77\xff\x00\x00\x00\x00\x00\x00\x00\x00\xc0\xff\x00\x00\xee\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x86\xff\x00\x00\x87\xff\x8a\xff\x00\x00\x8b\xff\x00\x00\x00\x00\x00\x00\xf4\xff\x00\x00\xee\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x81\xff\x78\xff\x7f\xff\x00\x00\x00\x00\x00\x00\xe1\xff\x00\x00\xf9\xff\xed\xff\x00\x00\xbe\xff\xbc\xff\xbd\xff\x00\x00\xa9\xff\x00\x00\x00\x00\x00\x00\x00\x00\x6a\xff\x00\x00\x00\x00\xb0\xff\x00\x00\xad\xff\xc9\xff\x00\x00\xb5\xff\xb6\xff\x00\x00\xe0\xff\x00\x00\x8d\xff\x8c\xff\x8f\xff\x91\xff\x95\xff\x96\xff\x8e\xff\x90\xff\x92\xff\x93\xff\x94\xff\x97\xff\x98\xff\x99\xff\x9a\xff\x9b\xff\xb3\xff\x71\xff\x6e\xff\x00\x00\x00\x00\xd1\xff\x00\x00\xbb\xff\x00\x00\x78\xff\x7e\xff\x00\x00\x00\x00\xc4\xff\x00\x00\x00\x00\x00\x00\x00\x00\xaf\xff\xae\xff\x00\x00\xc1\xff\x75\xff\xca\xff\x00\x00\xa1\xff\xa9\xff\x00\x00\xc2\xff\x00\x00\xcd\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x83\xff\x00\x00\xf0\xff\xef\xff\xf2\xff\xf1\xff\x89\xff\x82\xff\x00\x00\x00\x00\x00\x00\x00\x00\xbf\xff\x00\x00\xa4\xff\xa8\xff\x00\x00\x00\x00\xab\xff\xc8\xff\x78\xff\xac\xff\xc6\xff\x00\x00\x00\x00\xa0\xff\x00\x00\x00\x00\x7a\xff\x00\x00\x7d\xff\x7c\xff\x00\x00\x00\x00\x00\x00\xb2\xff\x79\xff\xd0\xff\x78\xff\xc3\xff\x00\x00\x9d\xff\x9e\xff\x00\x00\x00\x00\xcc\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe3\xff\x00\x00\x00\x00\x00\x00\xa7\xff\xe0\xff\x00\x00\xa3\xff\xe0\xff\x00\x00\xe0\xff\x00\x00\xba\xff\xb1\xff\x7b\xff\xce\xff\x00\x00\x00\x00\x00\x00\x00\x00\xc7\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe6\xff\xa6\xff\xa5\xff\xa2\xff\x9f\xff\xc5\xff\xb9\xff\xcf\xff\x00\x00\x00\x00\xe4\xff\xe5\xff"#

happyCheck :: HappyAddr
happyCheck = HappyA# "\xff\xff\x02\x00\x12\x00\x07\x00\x03\x00\x25\x00\x07\x00\x4d\x00\x06\x00\x03\x00\x0b\x00\x04\x00\x05\x00\x0e\x00\x0f\x00\x23\x00\x08\x00\x01\x00\x22\x00\x23\x00\x02\x00\x36\x00\x2a\x00\x07\x00\x49\x00\x07\x00\x2a\x00\x07\x00\x20\x00\x21\x00\x16\x00\x07\x00\x34\x00\x35\x00\x02\x00\x07\x00\x34\x00\x35\x00\x07\x00\x07\x00\x05\x00\x49\x00\x4a\x00\x06\x00\x32\x00\x49\x00\x34\x00\x2e\x00\x02\x00\x03\x00\x0d\x00\x07\x00\x2e\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x07\x00\x34\x00\x35\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x48\x00\x49\x00\x4a\x00\x4b\x00\x4c\x00\x2c\x00\x4b\x00\x2e\x00\x2f\x00\x30\x00\x31\x00\x32\x00\x07\x00\x34\x00\x35\x00\x36\x00\x0b\x00\x38\x00\x39\x00\x0e\x00\x0f\x00\x3c\x00\x3d\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x48\x00\x49\x00\x07\x00\x4a\x00\x49\x00\x48\x00\x0b\x00\x49\x00\x4a\x00\x0e\x00\x0f\x00\x22\x00\x23\x00\x02\x00\x25\x00\x26\x00\x27\x00\x07\x00\x17\x00\x2a\x00\x16\x00\x0b\x00\x20\x00\x21\x00\x0e\x00\x0f\x00\x36\x00\x48\x00\x49\x00\x34\x00\x35\x00\x0c\x00\x0d\x00\x0e\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x48\x00\x49\x00\x4a\x00\x4b\x00\x4c\x00\x07\x00\x31\x00\x32\x00\x33\x00\x34\x00\x35\x00\x49\x00\x0e\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x48\x00\x49\x00\x4a\x00\x4b\x00\x4c\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x48\x00\x49\x00\x4a\x00\x4b\x00\x4c\x00\x00\x00\x01\x00\x02\x00\x49\x00\x00\x00\x01\x00\x02\x00\x07\x00\x02\x00\x03\x00\x0a\x00\x07\x00\x0c\x00\x03\x00\x0a\x00\x02\x00\x0c\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x48\x00\x49\x00\x4a\x00\x4b\x00\x4c\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x04\x00\x05\x00\x20\x00\x21\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x34\x00\x35\x00\x0d\x00\x0e\x00\x34\x00\x35\x00\x22\x00\x23\x00\x0b\x00\x0c\x00\x49\x00\x0b\x00\x0c\x00\x10\x00\x0d\x00\x0e\x00\x10\x00\x34\x00\x35\x00\x0b\x00\x0c\x00\x16\x00\x0b\x00\x0c\x00\x10\x00\x1b\x00\x1c\x00\x10\x00\x49\x00\x49\x00\x0b\x00\x0c\x00\x2c\x00\x2d\x00\x2e\x00\x10\x00\x1b\x00\x1c\x00\x34\x00\x35\x00\x2b\x00\x02\x00\x4a\x00\x2b\x00\x2f\x00\x07\x00\x49\x00\x2f\x00\x49\x00\x34\x00\x35\x00\x2b\x00\x34\x00\x35\x00\x2b\x00\x2f\x00\x49\x00\x25\x00\x2f\x00\x16\x00\x34\x00\x35\x00\x2b\x00\x34\x00\x35\x00\x16\x00\x2f\x00\x16\x00\x0b\x00\x0c\x00\x16\x00\x34\x00\x35\x00\x10\x00\x16\x00\x0b\x00\x0c\x00\x16\x00\x49\x00\x49\x00\x10\x00\x01\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x4b\x00\x4b\x00\x49\x00\x22\x00\x23\x00\x4b\x00\x4b\x00\x4b\x00\x2b\x00\x28\x00\x29\x00\x2a\x00\x2f\x00\x08\x00\x16\x00\x2b\x00\x49\x00\x34\x00\x35\x00\x2f\x00\x04\x00\x34\x00\x35\x00\x09\x00\x34\x00\x35\x00\x25\x00\x26\x00\x27\x00\x28\x00\x29\x00\x2a\x00\x49\x00\x2c\x00\x2d\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x07\x00\x05\x00\x07\x00\x38\x00\x48\x00\x16\x00\x16\x00\x1a\x00\x1b\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x16\x00\x49\x00\x15\x00\x16\x00\x15\x00\x16\x00\x15\x00\x16\x00\x15\x00\x16\x00\x31\x00\x32\x00\x33\x00\x34\x00\x35\x00\x22\x00\x23\x00\x22\x00\x23\x00\x22\x00\x23\x00\x22\x00\x23\x00\x2a\x00\x16\x00\x2a\x00\x04\x00\x2a\x00\x16\x00\x2a\x00\x15\x00\x16\x00\x05\x00\x34\x00\x35\x00\x34\x00\x35\x00\x34\x00\x35\x00\x34\x00\x35\x00\x22\x00\x23\x00\x22\x00\x23\x00\x07\x00\x05\x00\x28\x00\x29\x00\x2a\x00\x4b\x00\x2a\x00\x49\x00\x02\x00\x32\x00\x33\x00\x34\x00\x35\x00\x0a\x00\x34\x00\x35\x00\x34\x00\x35\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x02\x00\x05\x00\x19\x00\x49\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x02\x00\x4b\x00\x4b\x00\x4b\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x08\x00\x03\x00\x4b\x00\x02\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x09\x00\x4b\x00\x02\x00\x08\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x05\x00\x16\x00\x07\x00\x49\x00\x08\x00\x4a\x00\x0e\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x49\x00\x49\x00\x09\x00\x09\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x06\x00\x08\x00\x24\x00\x02\x00\x08\x00\x18\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x08\x00\x08\x00\x02\x00\x16\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x06\x00\x08\x00\x16\x00\x16\x00\x07\x00\x06\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x06\x00\x16\x00\x49\x00\x02\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x07\x00\x16\x00\x4a\x00\x02\x00\x08\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x02\x00\x0a\x00\x4a\x00\x02\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x07\x00\x4b\x00\x4b\x00\x4b\x00\x16\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x3a\x00\x4b\x00\x02\x00\x08\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x08\x00\x06\x00\x06\x00\x16\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x08\x00\x20\x00\x09\x00\x01\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x09\x00\x49\x00\x30\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x07\x00\x07\x00\x02\x00\x04\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x16\x00\x48\x00\x06\x00\x3b\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x16\x00\x3a\x00\x4b\x00\x48\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x08\x00\x16\x00\x16\x00\x16\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\x12\x00\x13\x00\x14\x00\x15\x00\x4a\x00\x4a\x00\x16\x00\x4b\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x1e\x00\x1f\x00\x22\x00\x23\x00\x01\x00\x22\x00\x23\x00\x4a\x00\x28\x00\x29\x00\x2a\x00\x28\x00\x29\x00\x2a\x00\x16\x00\x04\x00\x01\x00\x08\x00\x08\x00\x2b\x00\x34\x00\x35\x00\x16\x00\x34\x00\x35\x00\x22\x00\x23\x00\x08\x00\x22\x00\x23\x00\x08\x00\x28\x00\x29\x00\x2a\x00\x28\x00\x29\x00\x2a\x00\x02\x00\x08\x00\x4a\x00\x03\x00\x03\x00\x4b\x00\x34\x00\x35\x00\x16\x00\x34\x00\x35\x00\x22\x00\x23\x00\x16\x00\x22\x00\x23\x00\x16\x00\x28\x00\x29\x00\x2a\x00\x28\x00\x29\x00\x2a\x00\x22\x00\x23\x00\x4a\x00\x08\x00\x26\x00\x27\x00\x34\x00\x35\x00\x2a\x00\x34\x00\x35\x00\x4a\x00\x4a\x00\x02\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x28\x00\x29\x00\x2a\x00\x29\x00\x2a\x00\x49\x00\x08\x00\x33\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x02\x00\x2a\x00\x37\x00\x08\x00\x02\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x04\x00\x2a\x00\x04\x00\x4b\x00\x02\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x04\x00\x2a\x00\x16\x00\x16\x00\x0f\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x4a\x00\x2a\x00\x08\x00\x08\x00\x08\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x09\x00\x2a\x00\x1a\x00\x0f\x00\x0f\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x30\x00\x2a\x00\x06\x00\x03\x00\x0f\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x11\x00\x2a\x00\x24\x00\x24\x00\x18\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x21\x00\x2a\x00\x2e\x00\x13\x00\x19\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x06\x00\x2a\x00\x06\x00\x2f\x00\x09\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x09\x00\x2a\x00\x19\x00\x1f\x00\x1e\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x11\x00\x2a\x00\x20\x00\x17\x00\x1e\x00\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\x14\x00\x2a\x00\xff\xff\x1d\x00\xff\xff\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\xff\xff\x2a\x00\xff\xff\xff\xff\xff\xff\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\xff\xff\x2a\x00\xff\xff\xff\xff\xff\xff\x22\x00\x23\x00\x22\x00\x23\x00\x34\x00\x35\x00\x34\x00\x35\x00\x2a\x00\xff\xff\x2a\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\x11\x00\xff\xff\x34\x00\x35\x00\x34\x00\x35\x00\xff\xff\xff\xff\xff\xff\x1a\x00\x1b\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\x1a\x00\x1b\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\xff\xff\x49\x00\x4a\x00\x3e\x00\x3f\x00\x40\x00\x41\x00\x42\x00\x43\x00\x44\x00\x45\x00\x46\x00\x47\x00\x2c\x00\x2d\x00\x2e\x00\xff\xff\xff\xff\xff\xff\x32\x00\x33\x00\x34\x00\x35\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"#

happyTable :: HappyAddr
happyTable = HappyA# "\x00\x00\x7c\x00\x03\x01\xcd\x00\x18\x01\x21\x00\x7d\x00\xff\xff\xf1\x00\x87\x01\x7e\x00\x6e\x00\x6f\x00\x7f\x00\x80\x00\x53\x01\x8b\x00\x91\x00\x04\x01\x78\x00\x61\x01\x2f\x00\x79\x00\x92\x00\x26\x00\x62\x01\x79\x00\x2c\x00\xce\x00\xcf\x00\x8c\x00\x2b\x00\x7a\x00\x09\x00\x58\x00\x2a\x00\x7a\x00\x09\x00\x29\x00\x59\x00\xa8\x00\x22\x00\x23\x00\x10\x01\xaa\x00\x26\x00\xab\x00\x19\x01\x50\x00\x51\x00\x11\x01\x28\x00\x88\x01\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\x27\x00\x70\x00\x71\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x81\x00\x82\x00\x83\x00\x84\x00\x85\x00\x11\x00\xf2\x00\x5a\x00\x5b\x00\x5c\x00\x5d\x00\x72\xff\x7d\x00\x72\xff\x5e\x00\x5f\x00\x7e\x00\x13\x00\x60\x00\x7f\x00\x80\x00\x61\x00\x62\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x63\x00\x64\x00\x9f\x00\x24\x00\x26\x00\x12\x01\x7e\x00\xa6\x00\xa7\x00\x7f\x00\x80\x00\x69\x01\x78\x00\x40\x00\x6a\x01\x6b\x01\x6c\x01\x7d\x00\xa0\x00\x79\x00\x3f\x00\x7e\x00\xce\x00\xcf\x00\x7f\x00\x80\x00\x06\x01\x63\x00\x0d\x01\x7a\x00\x09\x00\xbc\x00\xbd\x00\xbe\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x81\x00\x82\x00\x83\x00\x84\x00\x85\x00\x7d\x00\x4a\x00\x4b\x00\x4c\x00\x4d\x00\x09\x00\x3e\x00\x7f\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x81\x00\x82\x00\x83\x00\x84\x00\x85\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x81\x00\x82\x00\x83\x00\x84\x00\x85\x00\x02\x00\x03\x00\x04\x00\x3d\x00\x2f\x00\x03\x00\x04\x00\x05\x00\x50\x00\x51\x00\x06\x00\x05\x00\x07\x00\x3c\x00\x06\x00\x3b\x00\x07\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x81\x00\x82\x00\x83\x00\x84\x00\x85\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x85\x00\x6f\x00\xce\x00\xcf\x00\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\x08\x00\x09\x00\x1e\x00\x1f\x00\x08\x00\x09\x00\x65\x01\x66\x01\x51\x00\x52\x00\x39\x00\xac\x00\x52\x00\x53\x00\x40\x00\x1f\x00\x53\x00\xfa\x00\x09\x00\xab\x00\x52\x00\x3a\x00\x37\x01\x52\x00\x53\x00\x42\x01\x43\x01\x53\x00\x38\x00\x37\x00\x98\x01\x52\x00\x2b\x01\xa2\x00\xa3\x00\x53\x00\x5c\x01\x43\x01\x70\x00\x71\x00\x54\x00\x33\x00\x72\x01\x54\x00\x55\x00\x32\x00\x36\x00\x55\x00\x35\x00\x56\x00\x09\x00\x54\x00\x56\x00\x09\x00\x54\x00\x55\x00\x34\x00\x73\x00\x55\x00\x4a\x00\x56\x00\x09\x00\x54\x00\x56\x00\x09\x00\x49\x00\x55\x00\x48\x00\x96\x01\x52\x00\x47\x00\x56\x00\x09\x00\x53\x00\x46\x00\x94\x01\x52\x00\x45\x00\x26\x00\x43\x00\x53\x00\x6e\x00\x74\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x6d\x00\x6c\x00\x68\x00\xd4\x00\x78\x00\x6b\x00\x6a\x00\x69\x00\x54\x00\xdc\x00\xd6\x00\x79\x00\x55\x00\x67\x00\x66\x00\x54\x00\x65\x00\x56\x00\x09\x00\x55\x00\xae\x00\x7a\x00\x09\x00\xa9\x00\x56\x00\x09\x00\x0b\x00\x0c\x00\x0d\x00\x0e\x00\x0f\x00\x10\x00\xa1\x00\x11\x00\x12\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\x98\x00\x97\x00\x95\x00\x13\x00\x94\x00\x8f\x00\x8d\x00\xc6\x00\xc7\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x8a\x00\x1e\x00\x9b\x00\x9c\x00\xb8\x00\xb9\x00\xb7\x00\x9c\x00\x15\x01\x9c\x00\xe0\x00\x4b\x00\x4c\x00\x4d\x00\x09\x00\x9d\x00\x78\x00\xba\x00\x78\x00\x9d\x00\x78\x00\x9d\x00\x78\x00\x79\x00\x89\x00\x79\x00\x87\x00\x79\x00\x88\x00\x79\x00\x14\x01\x9c\x00\x77\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\xd4\x00\x78\x00\x9d\x00\x78\x00\x76\x00\x75\x00\xd9\x00\xd6\x00\x79\x00\xef\x00\x79\x00\xf0\x00\xee\x00\x8f\x00\x4c\x00\x4d\x00\x09\x00\xed\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x2f\x01\xec\x00\xe6\x00\xe9\x00\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x73\x01\xe4\x00\xe3\x00\xe2\x00\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\xdf\x00\x08\x01\xe0\x00\xdc\x00\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\xdb\x00\xd8\x00\xb7\x00\xb6\x00\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xd2\x00\xb5\x00\xd3\x00\xa6\x00\xb4\x00\xb0\x00\xaf\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x32\x01\x31\x01\x2d\x01\x2b\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\x2e\x01\x2a\x01\x17\x01\x13\x01\x0a\x01\x09\x01\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x07\x01\x03\x01\x01\x01\x00\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\x4e\x01\xff\x00\xfe\x00\xfd\x00\xfa\x00\xf6\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\xf3\x00\xfc\x00\xf7\x00\x53\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xd0\x00\x8f\x00\xf4\x00\x52\x01\x51\x01\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x50\x01\x4f\x01\x4c\x01\x48\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\x74\x01\x4b\x01\x4a\x01\x49\x01\x47\x01\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x45\x01\x42\x01\x41\x01\x3e\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xf9\x00\x3d\x01\x3c\x01\x3b\x01\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x3a\x01\xce\x00\x35\x01\x39\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xd4\x00\x37\x01\x36\x01\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x34\x01\x33\x01\x64\x01\x67\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x0b\x01\x12\x01\x60\x01\x5f\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x8f\x00\x45\x01\x5c\x01\x94\x00\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\xc4\x00\xc5\x00\x55\x01\x59\x01\x58\x01\x57\x01\xc6\x00\xc7\x00\xc8\x00\xc9\x00\xca\x00\xcb\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\xc2\x00\xc3\x00\x00\x00\x00\x00\x81\x01\x7f\x01\x56\x01\x80\x01\xc6\x00\xc7\x00\x00\x00\x00\x00\x00\x00\x00\x00\xd4\x00\x78\x00\x7d\x01\xd4\x00\x78\x00\x7e\x01\xd5\x00\xd6\x00\x79\x00\x13\x01\xd6\x00\x79\x00\x7c\x01\x7b\x01\x7a\x01\x78\x01\x77\x01\x76\x01\x7a\x00\x09\x00\x70\x01\x7a\x00\x09\x00\xd4\x00\x78\x00\x71\x01\xd4\x00\x78\x00\x6f\x01\x0d\x01\xd6\x00\x79\x00\x4c\x01\xd6\x00\x79\x00\x91\x01\x8b\x01\x8f\x01\x8c\x01\x8a\x01\x5c\x01\x7a\x00\x09\x00\x85\x01\x7a\x00\x09\x00\xd4\x00\x78\x00\x84\x01\xd4\x00\x78\x00\x83\x01\x6d\x01\xd6\x00\x79\x00\x78\x01\xd6\x00\x79\x00\x69\x01\x78\x00\x9c\x01\x82\x01\x8f\x01\x6c\x01\x7a\x00\x09\x00\x79\x00\x7a\x00\x09\x00\x9b\x01\x9a\x01\x96\x01\xd4\x00\x78\x00\xd4\x00\x78\x00\x7a\x00\x09\x00\x8c\x01\xd6\x00\x79\x00\x3f\x01\x79\x00\x98\x01\x94\x01\x93\x01\x9a\x00\x78\x00\x99\x00\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\xa6\x01\x79\x00\xa5\x01\x9f\x01\xa4\x01\x98\x00\x78\x00\x77\x00\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\xa3\x01\x79\x00\xa2\x01\xa7\x01\xa1\x01\xea\x00\x78\x00\xe9\x00\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\xa0\x01\x79\x00\x9e\x01\x9d\x01\x2c\x00\xe7\x00\x78\x00\xdd\x00\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\xa8\x01\x79\x00\xaa\x01\xa9\x01\x2d\x00\xd8\x00\x78\x00\xb1\x00\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x4e\x00\x79\x00\x95\x00\x24\x00\x43\x00\xb0\x00\x78\x00\x28\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x30\x00\x79\x00\x8d\x00\x41\x00\x2c\x00\x27\x01\x78\x00\x26\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x92\x00\x79\x00\xe6\x00\xe4\x00\xd0\x00\x25\x01\x78\x00\x24\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\xcb\x00\x79\x00\xb2\x00\x2f\x01\x0e\x01\x23\x01\x78\x00\x22\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x01\x01\x79\x00\xf4\x00\x0b\x01\x45\x01\x21\x01\x78\x00\x20\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x3e\x01\x79\x00\x62\x01\x5d\x01\x5a\x01\x1f\x01\x78\x00\x1e\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x59\x01\x79\x00\x74\x01\x8d\x01\x88\x01\x1d\x01\x78\x00\x1c\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x91\x01\x79\x00\x00\x00\x85\x01\x00\x00\x1b\x01\x78\x00\x1a\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x00\x00\x79\x00\x00\x00\x00\x00\x00\x00\x19\x01\x78\x00\xf7\x00\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x00\x00\x79\x00\x00\x00\x00\x00\x00\x00\x68\x01\x78\x00\x67\x01\x78\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x79\x00\x00\x00\x79\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\xc1\x00\x00\x00\x7a\x00\x09\x00\x7a\x00\x09\x00\x00\x00\x00\x00\x00\x00\xc6\x00\xc7\x00\xbc\x00\xbd\x00\xbe\x00\xbf\x00\xc0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xc6\x00\xc7\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\x00\x00\xa6\x00\xa7\x00\x14\x00\x15\x00\x16\x00\x17\x00\x18\x00\x19\x00\x1a\x00\x1b\x00\x1c\x00\x1d\x00\xa1\x00\xa2\x00\xa3\x00\x00\x00\x00\x00\x00\x00\xa4\x00\x4c\x00\x4d\x00\x09\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"#

happyReduceArr = Happy_Data_Array.array (1, 169) [
	(1 , happyReduce_1),
	(2 , happyReduce_2),
	(3 , happyReduce_3),
	(4 , happyReduce_4),
	(5 , happyReduce_5),
	(6 , happyReduce_6),
	(7 , happyReduce_7),
	(8 , happyReduce_8),
	(9 , happyReduce_9),
	(10 , happyReduce_10),
	(11 , happyReduce_11),
	(12 , happyReduce_12),
	(13 , happyReduce_13),
	(14 , happyReduce_14),
	(15 , happyReduce_15),
	(16 , happyReduce_16),
	(17 , happyReduce_17),
	(18 , happyReduce_18),
	(19 , happyReduce_19),
	(20 , happyReduce_20),
	(21 , happyReduce_21),
	(22 , happyReduce_22),
	(23 , happyReduce_23),
	(24 , happyReduce_24),
	(25 , happyReduce_25),
	(26 , happyReduce_26),
	(27 , happyReduce_27),
	(28 , happyReduce_28),
	(29 , happyReduce_29),
	(30 , happyReduce_30),
	(31 , happyReduce_31),
	(32 , happyReduce_32),
	(33 , happyReduce_33),
	(34 , happyReduce_34),
	(35 , happyReduce_35),
	(36 , happyReduce_36),
	(37 , happyReduce_37),
	(38 , happyReduce_38),
	(39 , happyReduce_39),
	(40 , happyReduce_40),
	(41 , happyReduce_41),
	(42 , happyReduce_42),
	(43 , happyReduce_43),
	(44 , happyReduce_44),
	(45 , happyReduce_45),
	(46 , happyReduce_46),
	(47 , happyReduce_47),
	(48 , happyReduce_48),
	(49 , happyReduce_49),
	(50 , happyReduce_50),
	(51 , happyReduce_51),
	(52 , happyReduce_52),
	(53 , happyReduce_53),
	(54 , happyReduce_54),
	(55 , happyReduce_55),
	(56 , happyReduce_56),
	(57 , happyReduce_57),
	(58 , happyReduce_58),
	(59 , happyReduce_59),
	(60 , happyReduce_60),
	(61 , happyReduce_61),
	(62 , happyReduce_62),
	(63 , happyReduce_63),
	(64 , happyReduce_64),
	(65 , happyReduce_65),
	(66 , happyReduce_66),
	(67 , happyReduce_67),
	(68 , happyReduce_68),
	(69 , happyReduce_69),
	(70 , happyReduce_70),
	(71 , happyReduce_71),
	(72 , happyReduce_72),
	(73 , happyReduce_73),
	(74 , happyReduce_74),
	(75 , happyReduce_75),
	(76 , happyReduce_76),
	(77 , happyReduce_77),
	(78 , happyReduce_78),
	(79 , happyReduce_79),
	(80 , happyReduce_80),
	(81 , happyReduce_81),
	(82 , happyReduce_82),
	(83 , happyReduce_83),
	(84 , happyReduce_84),
	(85 , happyReduce_85),
	(86 , happyReduce_86),
	(87 , happyReduce_87),
	(88 , happyReduce_88),
	(89 , happyReduce_89),
	(90 , happyReduce_90),
	(91 , happyReduce_91),
	(92 , happyReduce_92),
	(93 , happyReduce_93),
	(94 , happyReduce_94),
	(95 , happyReduce_95),
	(96 , happyReduce_96),
	(97 , happyReduce_97),
	(98 , happyReduce_98),
	(99 , happyReduce_99),
	(100 , happyReduce_100),
	(101 , happyReduce_101),
	(102 , happyReduce_102),
	(103 , happyReduce_103),
	(104 , happyReduce_104),
	(105 , happyReduce_105),
	(106 , happyReduce_106),
	(107 , happyReduce_107),
	(108 , happyReduce_108),
	(109 , happyReduce_109),
	(110 , happyReduce_110),
	(111 , happyReduce_111),
	(112 , happyReduce_112),
	(113 , happyReduce_113),
	(114 , happyReduce_114),
	(115 , happyReduce_115),
	(116 , happyReduce_116),
	(117 , happyReduce_117),
	(118 , happyReduce_118),
	(119 , happyReduce_119),
	(120 , happyReduce_120),
	(121 , happyReduce_121),
	(122 , happyReduce_122),
	(123 , happyReduce_123),
	(124 , happyReduce_124),
	(125 , happyReduce_125),
	(126 , happyReduce_126),
	(127 , happyReduce_127),
	(128 , happyReduce_128),
	(129 , happyReduce_129),
	(130 , happyReduce_130),
	(131 , happyReduce_131),
	(132 , happyReduce_132),
	(133 , happyReduce_133),
	(134 , happyReduce_134),
	(135 , happyReduce_135),
	(136 , happyReduce_136),
	(137 , happyReduce_137),
	(138 , happyReduce_138),
	(139 , happyReduce_139),
	(140 , happyReduce_140),
	(141 , happyReduce_141),
	(142 , happyReduce_142),
	(143 , happyReduce_143),
	(144 , happyReduce_144),
	(145 , happyReduce_145),
	(146 , happyReduce_146),
	(147 , happyReduce_147),
	(148 , happyReduce_148),
	(149 , happyReduce_149),
	(150 , happyReduce_150),
	(151 , happyReduce_151),
	(152 , happyReduce_152),
	(153 , happyReduce_153),
	(154 , happyReduce_154),
	(155 , happyReduce_155),
	(156 , happyReduce_156),
	(157 , happyReduce_157),
	(158 , happyReduce_158),
	(159 , happyReduce_159),
	(160 , happyReduce_160),
	(161 , happyReduce_161),
	(162 , happyReduce_162),
	(163 , happyReduce_163),
	(164 , happyReduce_164),
	(165 , happyReduce_165),
	(166 , happyReduce_166),
	(167 , happyReduce_167),
	(168 , happyReduce_168),
	(169 , happyReduce_169)
	]

happy_n_terms = 78 :: Int
happy_n_nonterms = 54 :: Int

happyReduce_1 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_1 = happySpecReduce_0  0# happyReduction_1
happyReduction_1  =  happyIn4
		 (return ()
	)

happyReduce_2 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_2 = happySpecReduce_2  0# happyReduction_2
happyReduction_2 happy_x_2
	happy_x_1
	 =  case happyOut5 happy_x_1 of { (HappyWrap5 happy_var_1) -> 
	case happyOut4 happy_x_2 of { (HappyWrap4 happy_var_2) -> 
	happyIn4
		 (do happy_var_1; happy_var_2
	)}}

happyReduce_3 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_3 = happySpecReduce_1  1# happyReduction_3
happyReduction_3 happy_x_1
	 =  case happyOut11 happy_x_1 of { (HappyWrap11 happy_var_1) -> 
	happyIn5
		 (happy_var_1
	)}

happyReduce_4 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_4 = happySpecReduce_1  1# happyReduction_4
happyReduction_4 happy_x_1
	 =  case happyOut6 happy_x_1 of { (HappyWrap6 happy_var_1) -> 
	happyIn5
		 (happy_var_1
	)}

happyReduce_5 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_5 = happySpecReduce_1  1# happyReduction_5
happyReduction_5 happy_x_1
	 =  case happyOut16 happy_x_1 of { (HappyWrap16 happy_var_1) -> 
	happyIn5
		 (happy_var_1
	)}

happyReduce_6 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_6 = happyMonadReduce 8# 1# happyReduction_6
happyReduction_6 (happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Name        happy_var_5)) -> 
	case happyOut10 happy_x_6 of { (HappyWrap10 happy_var_6) -> 
	( liftP . withThisPackage $ \pkg ->
                   do lits <- sequence happy_var_6;
                      staticClosure pkg happy_var_3 happy_var_5 (map getLit lits))}}})
	) (\r -> happyReturn (happyIn5 r))

happyReduce_7 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_7 = happyReduce 6# 2# happyReduction_7
happyReduction_7 (happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_2 of { (L _ (CmmT_String      happy_var_2)) -> 
	case happyOut7 happy_x_4 of { (HappyWrap7 happy_var_4) -> 
	case happyOut8 happy_x_5 of { (HappyWrap8 happy_var_5) -> 
	happyIn6
		 (do lbl <- happy_var_4;
                     ss <- sequence happy_var_5;
                     code (emitDecl (CmmData (Section (section happy_var_2) lbl) (Statics lbl $ concat ss)))
	) `HappyStk` happyRest}}}

happyReduce_8 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_8 = happyMonadReduce 2# 3# happyReduction_8
happyReduction_8 (happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	( liftP . withThisPackage $ \pkg ->
                   return (mkCmmDataLabel pkg (NeedExternDecl False) happy_var_1))})
	) (\r -> happyReturn (happyIn7 r))

happyReduce_9 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_9 = happySpecReduce_0  4# happyReduction_9
happyReduction_9  =  happyIn8
		 ([]
	)

happyReduce_10 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_10 = happySpecReduce_2  4# happyReduction_10
happyReduction_10 happy_x_2
	happy_x_1
	 =  case happyOut9 happy_x_1 of { (HappyWrap9 happy_var_1) -> 
	case happyOut8 happy_x_2 of { (HappyWrap8 happy_var_2) -> 
	happyIn8
		 (happy_var_1 : happy_var_2
	)}}

happyReduce_11 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_11 = happySpecReduce_3  5# happyReduction_11
happyReduction_11 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	happyIn9
		 (do e <- happy_var_2;
                             return [CmmStaticLit (getLit e)]
	)}

happyReduce_12 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_12 = happySpecReduce_2  5# happyReduction_12
happyReduction_12 happy_x_2
	happy_x_1
	 =  case happyOut56 happy_x_1 of { (HappyWrap56 happy_var_1) -> 
	happyIn9
		 (return [CmmUninitialised
                                                        (widthInBytes (typeWidth happy_var_1))]
	)}

happyReduce_13 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_13 = happyReduce 5# 5# happyReduction_13
happyReduction_13 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_4 of { (L _ (CmmT_String      happy_var_4)) -> 
	happyIn9
		 (return [mkString happy_var_4]
	) `HappyStk` happyRest}

happyReduce_14 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_14 = happyReduce 5# 5# happyReduction_14
happyReduction_14 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_3 of { (L _ (CmmT_Int         happy_var_3)) -> 
	happyIn9
		 (return [CmmUninitialised
                                                        (fromIntegral happy_var_3)]
	) `HappyStk` happyRest}

happyReduce_15 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_15 = happyReduce 5# 5# happyReduction_15
happyReduction_15 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut57 happy_x_1 of { (HappyWrap57 happy_var_1) -> 
	case happyOutTok happy_x_3 of { (L _ (CmmT_Int         happy_var_3)) -> 
	happyIn9
		 (return [CmmUninitialised
                                                (widthInBytes (typeWidth happy_var_1) *
                                                        fromIntegral happy_var_3)]
	) `HappyStk` happyRest}}

happyReduce_16 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_16 = happyReduce 5# 5# happyReduction_16
happyReduction_16 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOut10 happy_x_4 of { (HappyWrap10 happy_var_4) -> 
	happyIn9
		 (do { lits <- sequence happy_var_4
                ; dflags <- getDynFlags
                     ; return $ map CmmStaticLit $
                        mkStaticClosure dflags (mkForeignLabel happy_var_3 Nothing ForeignLabelInExternalPackage IsData)
                         -- mkForeignLabel because these are only used
                         -- for CHARLIKE and INTLIKE closures in the RTS.
                        dontCareCCS (map getLit lits) [] [] [] }
	) `HappyStk` happyRest}}

happyReduce_17 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_17 = happySpecReduce_0  6# happyReduction_17
happyReduction_17  =  happyIn10
		 ([]
	)

happyReduce_18 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_18 = happySpecReduce_3  6# happyReduction_18
happyReduction_18 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	case happyOut10 happy_x_3 of { (HappyWrap10 happy_var_3) -> 
	happyIn10
		 (happy_var_2 : happy_var_3
	)}}

happyReduce_19 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_19 = happyReduce 4# 7# happyReduction_19
happyReduction_19 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut14 happy_x_1 of { (HappyWrap14 happy_var_1) -> 
	case happyOut12 happy_x_2 of { (HappyWrap12 happy_var_2) -> 
	case happyOut52 happy_x_3 of { (HappyWrap52 happy_var_3) -> 
	case happyOut13 happy_x_4 of { (HappyWrap13 happy_var_4) -> 
	happyIn11
		 (do ((entry_ret_label, info, stk_formals, formals), agraph) <-
                       getCodeScoped $ loopDecls $ do {
                         (entry_ret_label, info, stk_formals) <- happy_var_1;
                         dflags <- getDynFlags;
                         formals <- sequence (fromMaybe [] happy_var_3);
                         withName (showSDoc dflags (ppr entry_ret_label))
                           happy_var_4;
                         return (entry_ret_label, info, stk_formals, formals) }
                     let do_layout = isJust happy_var_3
                     code (emitProcWithStackFrame happy_var_2 info
                                entry_ret_label stk_formals formals agraph
                                do_layout )
	) `HappyStk` happyRest}}}}

happyReduce_20 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_20 = happySpecReduce_0  8# happyReduction_20
happyReduction_20  =  happyIn12
		 (NativeNodeCall
	)

happyReduce_21 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_21 = happySpecReduce_1  8# happyReduction_21
happyReduction_21 happy_x_1
	 =  happyIn12
		 (NativeReturn
	)

happyReduce_22 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_22 = happySpecReduce_1  9# happyReduction_22
happyReduction_22 happy_x_1
	 =  happyIn13
		 (return ()
	)

happyReduce_23 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_23 = happySpecReduce_3  9# happyReduction_23
happyReduction_23 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { happy_var_1 -> 
	case happyOut15 happy_x_2 of { (HappyWrap15 happy_var_2) -> 
	case happyOutTok happy_x_3 of { happy_var_3 -> 
	happyIn13
		 (withSourceNote happy_var_1 happy_var_3 happy_var_2
	)}}}

happyReduce_24 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_24 = happyMonadReduce 1# 10# happyReduction_24
happyReduction_24 (happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	( liftP . withThisPackage $ \pkg ->
                   do   newFunctionName happy_var_1 pkg
                        return (mkCmmCodeLabel pkg happy_var_1, Nothing, []))})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_25 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_25 = happyMonadReduce 14# 10# happyReduction_25
happyReduction_25 (happy_x_14 `HappyStk`
	happy_x_13 `HappyStk`
	happy_x_12 `HappyStk`
	happy_x_11 `HappyStk`
	happy_x_10 `HappyStk`
	happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Int         happy_var_5)) -> 
	case happyOutTok happy_x_7 of { (L _ (CmmT_Int         happy_var_7)) -> 
	case happyOutTok happy_x_9 of { (L _ (CmmT_Int         happy_var_9)) -> 
	case happyOutTok happy_x_11 of { (L _ (CmmT_String      happy_var_11)) -> 
	case happyOutTok happy_x_13 of { (L _ (CmmT_String      happy_var_13)) -> 
	( liftP . withThisPackage $ \pkg ->
                   do dflags <- getDynFlags
                      let prof = profilingInfo dflags happy_var_11 happy_var_13
                          rep  = mkRTSRep (fromIntegral happy_var_9) $
                                   mkHeapRep dflags False (fromIntegral happy_var_5)
                                                   (fromIntegral happy_var_7) Thunk
                              -- not really Thunk, but that makes the info table
                              -- we want.
                      return (mkCmmEntryLabel pkg happy_var_3,
                              Just $ CmmInfoTable { cit_lbl = mkCmmInfoLabel pkg happy_var_3
                                           , cit_rep = rep
                                           , cit_prof = prof, cit_srt = Nothing, cit_clo = Nothing },
                              []))}}}}}})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_26 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_26 = happyMonadReduce 16# 10# happyReduction_26
happyReduction_26 (happy_x_16 `HappyStk`
	happy_x_15 `HappyStk`
	happy_x_14 `HappyStk`
	happy_x_13 `HappyStk`
	happy_x_12 `HappyStk`
	happy_x_11 `HappyStk`
	happy_x_10 `HappyStk`
	happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Int         happy_var_5)) -> 
	case happyOutTok happy_x_7 of { (L _ (CmmT_Int         happy_var_7)) -> 
	case happyOutTok happy_x_9 of { (L _ (CmmT_Int         happy_var_9)) -> 
	case happyOutTok happy_x_11 of { (L _ (CmmT_String      happy_var_11)) -> 
	case happyOutTok happy_x_13 of { (L _ (CmmT_String      happy_var_13)) -> 
	case happyOutTok happy_x_15 of { (L _ (CmmT_Int         happy_var_15)) -> 
	( liftP . withThisPackage $ \pkg ->
                   do dflags <- getDynFlags
                      let prof = profilingInfo dflags happy_var_11 happy_var_13
                          ty   = Fun 0 (ArgSpec (fromIntegral happy_var_15))
                                -- Arity zero, arg_type happy_var_15
                          rep = mkRTSRep (fromIntegral happy_var_9) $
                                    mkHeapRep dflags False (fromIntegral happy_var_5)
                                                    (fromIntegral happy_var_7) ty
                      return (mkCmmEntryLabel pkg happy_var_3,
                              Just $ CmmInfoTable { cit_lbl = mkCmmInfoLabel pkg happy_var_3
                                           , cit_rep = rep
                                           , cit_prof = prof, cit_srt = Nothing, cit_clo = Nothing },
                              []))}}}}}}})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_27 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_27 = happyMonadReduce 16# 10# happyReduction_27
happyReduction_27 (happy_x_16 `HappyStk`
	happy_x_15 `HappyStk`
	happy_x_14 `HappyStk`
	happy_x_13 `HappyStk`
	happy_x_12 `HappyStk`
	happy_x_11 `HappyStk`
	happy_x_10 `HappyStk`
	happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Int         happy_var_5)) -> 
	case happyOutTok happy_x_7 of { (L _ (CmmT_Int         happy_var_7)) -> 
	case happyOutTok happy_x_9 of { (L _ (CmmT_Int         happy_var_9)) -> 
	case happyOutTok happy_x_11 of { (L _ (CmmT_Int         happy_var_11)) -> 
	case happyOutTok happy_x_13 of { (L _ (CmmT_String      happy_var_13)) -> 
	case happyOutTok happy_x_15 of { (L _ (CmmT_String      happy_var_15)) -> 
	( liftP . withThisPackage $ \pkg ->
                   do dflags <- getDynFlags
                      let prof = profilingInfo dflags happy_var_13 happy_var_15
                          ty  = Constr (fromIntegral happy_var_9)  -- Tag
                                       (BS8.pack happy_var_13)
                          rep = mkRTSRep (fromIntegral happy_var_11) $
                                  mkHeapRep dflags False (fromIntegral happy_var_5)
                                                  (fromIntegral happy_var_7) ty
                      return (mkCmmEntryLabel pkg happy_var_3,
                              Just $ CmmInfoTable { cit_lbl = mkCmmInfoLabel pkg happy_var_3
                                           , cit_rep = rep
                                           , cit_prof = prof, cit_srt = Nothing,cit_clo = Nothing },
                              []))}}}}}}})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_28 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_28 = happyMonadReduce 12# 10# happyReduction_28
happyReduction_28 (happy_x_12 `HappyStk`
	happy_x_11 `HappyStk`
	happy_x_10 `HappyStk`
	happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Int         happy_var_5)) -> 
	case happyOutTok happy_x_7 of { (L _ (CmmT_Int         happy_var_7)) -> 
	case happyOutTok happy_x_9 of { (L _ (CmmT_String      happy_var_9)) -> 
	case happyOutTok happy_x_11 of { (L _ (CmmT_String      happy_var_11)) -> 
	( liftP . withThisPackage $ \pkg ->
                   do dflags <- getDynFlags
                      let prof = profilingInfo dflags happy_var_9 happy_var_11
                          ty  = ThunkSelector (fromIntegral happy_var_5)
                          rep = mkRTSRep (fromIntegral happy_var_7) $
                                   mkHeapRep dflags False 0 0 ty
                      return (mkCmmEntryLabel pkg happy_var_3,
                              Just $ CmmInfoTable { cit_lbl = mkCmmInfoLabel pkg happy_var_3
                                           , cit_rep = rep
                                           , cit_prof = prof, cit_srt = Nothing, cit_clo = Nothing },
                              []))}}}}})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_29 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_29 = happyMonadReduce 6# 10# happyReduction_29
happyReduction_29 (happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Int         happy_var_5)) -> 
	( liftP . withThisPackage $ \pkg ->
                   do let prof = NoProfilingInfo
                          rep  = mkRTSRep (fromIntegral happy_var_5) $ mkStackRep []
                      return (mkCmmRetLabel pkg happy_var_3,
                              Just $ CmmInfoTable { cit_lbl = mkCmmRetInfoLabel pkg happy_var_3
                                           , cit_rep = rep
                                           , cit_prof = prof, cit_srt = Nothing, cit_clo = Nothing },
                              []))}})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_30 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_30 = happyMonadReduce 8# 10# happyReduction_30
happyReduction_30 (happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Int         happy_var_5)) -> 
	case happyOut53 happy_x_7 of { (HappyWrap53 happy_var_7) -> 
	( liftP . withThisPackage $ \pkg ->
                   do dflags <- getDynFlags
                      live <- sequence happy_var_7
                      let prof = NoProfilingInfo
                          -- drop one for the info pointer
                          bitmap = mkLiveness dflags (drop 1 live)
                          rep  = mkRTSRep (fromIntegral happy_var_5) $ mkStackRep bitmap
                      return (mkCmmRetLabel pkg happy_var_3,
                              Just $ CmmInfoTable { cit_lbl = mkCmmRetInfoLabel pkg happy_var_3
                                           , cit_rep = rep
                                           , cit_prof = prof, cit_srt = Nothing, cit_clo = Nothing },
                              live))}}})
	) (\r -> happyReturn (happyIn14 r))

happyReduce_31 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_31 = happySpecReduce_0  11# happyReduction_31
happyReduction_31  =  happyIn15
		 (return ()
	)

happyReduce_32 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_32 = happySpecReduce_2  11# happyReduction_32
happyReduction_32 happy_x_2
	happy_x_1
	 =  case happyOut16 happy_x_1 of { (HappyWrap16 happy_var_1) -> 
	case happyOut15 happy_x_2 of { (HappyWrap15 happy_var_2) -> 
	happyIn15
		 (do happy_var_1; happy_var_2
	)}}

happyReduce_33 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_33 = happySpecReduce_2  11# happyReduction_33
happyReduction_33 happy_x_2
	happy_x_1
	 =  case happyOut20 happy_x_1 of { (HappyWrap20 happy_var_1) -> 
	case happyOut15 happy_x_2 of { (HappyWrap15 happy_var_2) -> 
	happyIn15
		 (do happy_var_1; happy_var_2
	)}}

happyReduce_34 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_34 = happySpecReduce_3  12# happyReduction_34
happyReduction_34 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut56 happy_x_1 of { (HappyWrap56 happy_var_1) -> 
	case happyOut19 happy_x_2 of { (HappyWrap19 happy_var_2) -> 
	happyIn16
		 (mapM_ (newLocal happy_var_1) happy_var_2
	)}}

happyReduce_35 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_35 = happySpecReduce_3  12# happyReduction_35
happyReduction_35 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut17 happy_x_2 of { (HappyWrap17 happy_var_2) -> 
	happyIn16
		 (mapM_ newImport happy_var_2
	)}

happyReduce_36 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_36 = happySpecReduce_3  12# happyReduction_36
happyReduction_36 happy_x_3
	happy_x_2
	happy_x_1
	 =  happyIn16
		 (return ()
	)

happyReduce_37 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_37 = happySpecReduce_1  13# happyReduction_37
happyReduction_37 happy_x_1
	 =  case happyOut18 happy_x_1 of { (HappyWrap18 happy_var_1) -> 
	happyIn17
		 ([happy_var_1]
	)}

happyReduce_38 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_38 = happySpecReduce_3  13# happyReduction_38
happyReduction_38 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut18 happy_x_1 of { (HappyWrap18 happy_var_1) -> 
	case happyOut17 happy_x_3 of { (HappyWrap17 happy_var_3) -> 
	happyIn17
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_39 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_39 = happySpecReduce_1  14# happyReduction_39
happyReduction_39 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn18
		 ((happy_var_1, mkForeignLabel happy_var_1 Nothing ForeignLabelInExternalPackage IsFunction)
	)}

happyReduce_40 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_40 = happySpecReduce_2  14# happyReduction_40
happyReduction_40 happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_2 of { (L _ (CmmT_Name        happy_var_2)) -> 
	happyIn18
		 ((happy_var_2, mkForeignLabel happy_var_2 Nothing ForeignLabelInExternalPackage IsData)
	)}

happyReduce_41 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_41 = happySpecReduce_2  14# happyReduction_41
happyReduction_41 happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_String      happy_var_1)) -> 
	case happyOutTok happy_x_2 of { (L _ (CmmT_Name        happy_var_2)) -> 
	happyIn18
		 ((happy_var_2, mkCmmCodeLabel (fsToUnitId (mkFastString happy_var_1)) happy_var_2)
	)}}

happyReduce_42 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_42 = happySpecReduce_1  15# happyReduction_42
happyReduction_42 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn19
		 ([happy_var_1]
	)}

happyReduce_43 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_43 = happySpecReduce_3  15# happyReduction_43
happyReduction_43 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	case happyOut19 happy_x_3 of { (HappyWrap19 happy_var_3) -> 
	happyIn19
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_44 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_44 = happySpecReduce_1  16# happyReduction_44
happyReduction_44 happy_x_1
	 =  happyIn20
		 (return ()
	)

happyReduce_45 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_45 = happySpecReduce_2  16# happyReduction_45
happyReduction_45 happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn20
		 (do l <- newLabel happy_var_1; emitLabel l
	)}

happyReduce_46 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_46 = happyReduce 4# 16# happyReduction_46
happyReduction_46 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut51 happy_x_1 of { (HappyWrap51 happy_var_1) -> 
	case happyOutTok happy_x_2 of { happy_var_2 -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	case happyOutTok happy_x_4 of { happy_var_4 -> 
	happyIn20
		 (do reg <- happy_var_1; e <- happy_var_3; withSourceNote happy_var_2 happy_var_4 (emitAssign reg e)
	) `HappyStk` happyRest}}}}

happyReduce_47 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_47 = happyReduce 7# 16# happyReduction_47
happyReduction_47 (happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut56 happy_x_1 of { (HappyWrap56 happy_var_1) -> 
	case happyOutTok happy_x_2 of { happy_var_2 -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	case happyOut38 happy_x_6 of { (HappyWrap38 happy_var_6) -> 
	case happyOutTok happy_x_7 of { happy_var_7 -> 
	happyIn20
		 (withSourceNote happy_var_2 happy_var_7 (doStore happy_var_1 happy_var_3 happy_var_6)
	) `HappyStk` happyRest}}}}}

happyReduce_48 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_48 = happyMonadReduce 10# 16# happyReduction_48
happyReduction_48 (happy_x_10 `HappyStk`
	happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOut47 happy_x_1 of { (HappyWrap47 happy_var_1) -> 
	case happyOutTok happy_x_3 of { (L _ (CmmT_String      happy_var_3)) -> 
	case happyOut23 happy_x_4 of { (HappyWrap23 happy_var_4) -> 
	case happyOut41 happy_x_6 of { (HappyWrap41 happy_var_6) -> 
	case happyOut27 happy_x_8 of { (HappyWrap27 happy_var_8) -> 
	case happyOut24 happy_x_9 of { (HappyWrap24 happy_var_9) -> 
	( foreignCall happy_var_3 happy_var_1 happy_var_4 happy_var_6 happy_var_8 happy_var_9)}}}}}})
	) (\r -> happyReturn (happyIn20 r))

happyReduce_49 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_49 = happyMonadReduce 8# 16# happyReduction_49
happyReduction_49 (happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOut47 happy_x_1 of { (HappyWrap47 happy_var_1) -> 
	case happyOutTok happy_x_4 of { (L _ (CmmT_Name        happy_var_4)) -> 
	case happyOut44 happy_x_6 of { (HappyWrap44 happy_var_6) -> 
	( primCall happy_var_1 happy_var_4 happy_var_6)}}})
	) (\r -> happyReturn (happyIn20 r))

happyReduce_50 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_50 = happyMonadReduce 5# 16# happyReduction_50
happyReduction_50 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	case happyOut44 happy_x_3 of { (HappyWrap44 happy_var_3) -> 
	( stmtMacro happy_var_1 happy_var_3)}})
	) (\r -> happyReturn (happyIn20 r))

happyReduce_51 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_51 = happyReduce 7# 16# happyReduction_51
happyReduction_51 (happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut30 happy_x_2 of { (HappyWrap30 happy_var_2) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	case happyOut31 happy_x_5 of { (HappyWrap31 happy_var_5) -> 
	case happyOut35 happy_x_6 of { (HappyWrap35 happy_var_6) -> 
	happyIn20
		 (do as <- sequence happy_var_5; doSwitch happy_var_2 happy_var_3 as happy_var_6
	) `HappyStk` happyRest}}}}

happyReduce_52 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_52 = happySpecReduce_3  16# happyReduction_52
happyReduction_52 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_2 of { (L _ (CmmT_Name        happy_var_2)) -> 
	happyIn20
		 (do l <- lookupLabel happy_var_2; emit (mkBranch l)
	)}

happyReduce_53 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_53 = happyReduce 5# 16# happyReduction_53
happyReduction_53 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut44 happy_x_3 of { (HappyWrap44 happy_var_3) -> 
	happyIn20
		 (doReturn happy_var_3
	) `HappyStk` happyRest}

happyReduce_54 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_54 = happyReduce 4# 16# happyReduction_54
happyReduction_54 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	case happyOut28 happy_x_3 of { (HappyWrap28 happy_var_3) -> 
	happyIn20
		 (doRawJump happy_var_2 happy_var_3
	) `HappyStk` happyRest}}

happyReduce_55 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_55 = happyReduce 6# 16# happyReduction_55
happyReduction_55 (happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	case happyOut44 happy_x_4 of { (HappyWrap44 happy_var_4) -> 
	happyIn20
		 (doJumpWithStack happy_var_2 [] happy_var_4
	) `HappyStk` happyRest}}

happyReduce_56 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_56 = happyReduce 9# 16# happyReduction_56
happyReduction_56 (happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	case happyOut44 happy_x_4 of { (HappyWrap44 happy_var_4) -> 
	case happyOut44 happy_x_7 of { (HappyWrap44 happy_var_7) -> 
	happyIn20
		 (doJumpWithStack happy_var_2 happy_var_4 happy_var_7
	) `HappyStk` happyRest}}}

happyReduce_57 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_57 = happyReduce 6# 16# happyReduction_57
happyReduction_57 (happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	case happyOut44 happy_x_4 of { (HappyWrap44 happy_var_4) -> 
	happyIn20
		 (doCall happy_var_2 [] happy_var_4
	) `HappyStk` happyRest}}

happyReduce_58 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_58 = happyReduce 10# 16# happyReduction_58
happyReduction_58 (happy_x_10 `HappyStk`
	happy_x_9 `HappyStk`
	happy_x_8 `HappyStk`
	happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut54 happy_x_2 of { (HappyWrap54 happy_var_2) -> 
	case happyOut38 happy_x_6 of { (HappyWrap38 happy_var_6) -> 
	case happyOut44 happy_x_8 of { (HappyWrap44 happy_var_8) -> 
	happyIn20
		 (doCall happy_var_6 happy_var_2 happy_var_8
	) `HappyStk` happyRest}}}

happyReduce_59 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_59 = happyReduce 5# 16# happyReduction_59
happyReduction_59 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut25 happy_x_2 of { (HappyWrap25 happy_var_2) -> 
	case happyOut37 happy_x_3 of { (HappyWrap37 happy_var_3) -> 
	case happyOutTok happy_x_5 of { (L _ (CmmT_Name        happy_var_5)) -> 
	happyIn20
		 (do l <- lookupLabel happy_var_5; cmmRawIf happy_var_2 l happy_var_3
	) `HappyStk` happyRest}}}

happyReduce_60 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_60 = happyReduce 7# 16# happyReduction_60
happyReduction_60 (happy_x_7 `HappyStk`
	happy_x_6 `HappyStk`
	happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut25 happy_x_2 of { (HappyWrap25 happy_var_2) -> 
	case happyOut37 happy_x_3 of { (HappyWrap37 happy_var_3) -> 
	case happyOutTok happy_x_4 of { happy_var_4 -> 
	case happyOut15 happy_x_5 of { (HappyWrap15 happy_var_5) -> 
	case happyOutTok happy_x_6 of { happy_var_6 -> 
	case happyOut36 happy_x_7 of { (HappyWrap36 happy_var_7) -> 
	happyIn20
		 (cmmIfThenElse happy_var_2 (withSourceNote happy_var_4 happy_var_6 happy_var_5) happy_var_7 happy_var_3
	) `HappyStk` happyRest}}}}}}

happyReduce_61 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_61 = happyReduce 5# 16# happyReduction_61
happyReduction_61 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut44 happy_x_3 of { (HappyWrap44 happy_var_3) -> 
	case happyOut13 happy_x_5 of { (HappyWrap13 happy_var_5) -> 
	happyIn20
		 (pushStackFrame happy_var_3 happy_var_5
	) `HappyStk` happyRest}}

happyReduce_62 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_62 = happyReduce 5# 16# happyReduction_62
happyReduction_62 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	case happyOut51 happy_x_4 of { (HappyWrap51 happy_var_4) -> 
	case happyOut13 happy_x_5 of { (HappyWrap13 happy_var_5) -> 
	happyIn20
		 (reserveStackFrame happy_var_2 happy_var_4 happy_var_5
	) `HappyStk` happyRest}}}

happyReduce_63 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_63 = happySpecReduce_3  16# happyReduction_63
happyReduction_63 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut21 happy_x_2 of { (HappyWrap21 happy_var_2) -> 
	happyIn20
		 (happy_var_2 >>= code . emitUnwind
	)}

happyReduce_64 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_64 = happyReduce 5# 17# happyReduction_64
happyReduction_64 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_1 of { (L _ (CmmT_GlobalReg   happy_var_1)) -> 
	case happyOut22 happy_x_3 of { (HappyWrap22 happy_var_3) -> 
	case happyOut21 happy_x_5 of { (HappyWrap21 happy_var_5) -> 
	happyIn21
		 (do e <- happy_var_3; rest <- happy_var_5; return ((happy_var_1, e) : rest)
	) `HappyStk` happyRest}}}

happyReduce_65 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_65 = happySpecReduce_3  17# happyReduction_65
happyReduction_65 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_GlobalReg   happy_var_1)) -> 
	case happyOut22 happy_x_3 of { (HappyWrap22 happy_var_3) -> 
	happyIn21
		 (do e <- happy_var_3; return [(happy_var_1, e)]
	)}}

happyReduce_66 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_66 = happySpecReduce_1  18# happyReduction_66
happyReduction_66 happy_x_1
	 =  happyIn22
		 (do return Nothing
	)

happyReduce_67 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_67 = happySpecReduce_1  18# happyReduction_67
happyReduction_67 happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	happyIn22
		 (do e <- happy_var_1; return (Just e)
	)}

happyReduce_68 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_68 = happySpecReduce_1  19# happyReduction_68
happyReduction_68 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn23
		 (return (CmmLit (CmmLabel (mkForeignLabel happy_var_1 Nothing ForeignLabelInThisPackage IsFunction)))
	)}

happyReduce_69 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_69 = happySpecReduce_0  20# happyReduction_69
happyReduction_69  =  happyIn24
		 (CmmMayReturn
	)

happyReduce_70 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_70 = happySpecReduce_2  20# happyReduction_70
happyReduction_70 happy_x_2
	happy_x_1
	 =  happyIn24
		 (CmmNeverReturns
	)

happyReduce_71 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_71 = happySpecReduce_1  21# happyReduction_71
happyReduction_71 happy_x_1
	 =  case happyOut26 happy_x_1 of { (HappyWrap26 happy_var_1) -> 
	happyIn25
		 (happy_var_1
	)}

happyReduce_72 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_72 = happySpecReduce_1  21# happyReduction_72
happyReduction_72 happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	happyIn25
		 (do e <- happy_var_1; return (BoolTest e)
	)}

happyReduce_73 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_73 = happySpecReduce_3  22# happyReduction_73
happyReduction_73 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut25 happy_x_1 of { (HappyWrap25 happy_var_1) -> 
	case happyOut25 happy_x_3 of { (HappyWrap25 happy_var_3) -> 
	happyIn26
		 (do e1 <- happy_var_1; e2 <- happy_var_3;
                                          return (BoolAnd e1 e2)
	)}}

happyReduce_74 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_74 = happySpecReduce_3  22# happyReduction_74
happyReduction_74 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut25 happy_x_1 of { (HappyWrap25 happy_var_1) -> 
	case happyOut25 happy_x_3 of { (HappyWrap25 happy_var_3) -> 
	happyIn26
		 (do e1 <- happy_var_1; e2 <- happy_var_3;
                                          return (BoolOr e1 e2)
	)}}

happyReduce_75 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_75 = happySpecReduce_2  22# happyReduction_75
happyReduction_75 happy_x_2
	happy_x_1
	 =  case happyOut25 happy_x_2 of { (HappyWrap25 happy_var_2) -> 
	happyIn26
		 (do e <- happy_var_2; return (BoolNot e)
	)}

happyReduce_76 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_76 = happySpecReduce_3  22# happyReduction_76
happyReduction_76 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut26 happy_x_2 of { (HappyWrap26 happy_var_2) -> 
	happyIn26
		 (happy_var_2
	)}

happyReduce_77 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_77 = happySpecReduce_0  23# happyReduction_77
happyReduction_77  =  happyIn27
		 (PlayRisky
	)

happyReduce_78 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_78 = happyMonadReduce 1# 23# happyReduction_78
happyReduction_78 (happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_1 of { (L _ (CmmT_String      happy_var_1)) -> 
	( parseSafety happy_var_1)})
	) (\r -> happyReturn (happyIn27 r))

happyReduce_79 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_79 = happySpecReduce_2  24# happyReduction_79
happyReduction_79 happy_x_2
	happy_x_1
	 =  happyIn28
		 ([]
	)

happyReduce_80 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_80 = happyMonadReduce 3# 24# happyReduction_80
happyReduction_80 (happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((( do df <- getDynFlags
                                         ; return (realArgRegsCover df)))
	) (\r -> happyReturn (happyIn28 r))

happyReduce_81 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_81 = happySpecReduce_3  24# happyReduction_81
happyReduction_81 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut29 happy_x_2 of { (HappyWrap29 happy_var_2) -> 
	happyIn28
		 (happy_var_2
	)}

happyReduce_82 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_82 = happySpecReduce_1  25# happyReduction_82
happyReduction_82 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_GlobalReg   happy_var_1)) -> 
	happyIn29
		 ([happy_var_1]
	)}

happyReduce_83 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_83 = happySpecReduce_3  25# happyReduction_83
happyReduction_83 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_GlobalReg   happy_var_1)) -> 
	case happyOut29 happy_x_3 of { (HappyWrap29 happy_var_3) -> 
	happyIn29
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_84 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_84 = happyReduce 5# 26# happyReduction_84
happyReduction_84 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_2 of { (L _ (CmmT_Int         happy_var_2)) -> 
	case happyOutTok happy_x_4 of { (L _ (CmmT_Int         happy_var_4)) -> 
	happyIn30
		 (Just (happy_var_2, happy_var_4)
	) `HappyStk` happyRest}}

happyReduce_85 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_85 = happySpecReduce_0  26# happyReduction_85
happyReduction_85  =  happyIn30
		 (Nothing
	)

happyReduce_86 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_86 = happySpecReduce_0  27# happyReduction_86
happyReduction_86  =  happyIn31
		 ([]
	)

happyReduce_87 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_87 = happySpecReduce_2  27# happyReduction_87
happyReduction_87 happy_x_2
	happy_x_1
	 =  case happyOut32 happy_x_1 of { (HappyWrap32 happy_var_1) -> 
	case happyOut31 happy_x_2 of { (HappyWrap31 happy_var_2) -> 
	happyIn31
		 (happy_var_1 : happy_var_2
	)}}

happyReduce_88 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_88 = happyReduce 4# 28# happyReduction_88
happyReduction_88 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut34 happy_x_2 of { (HappyWrap34 happy_var_2) -> 
	case happyOut33 happy_x_4 of { (HappyWrap33 happy_var_4) -> 
	happyIn32
		 (do b <- happy_var_4; return (happy_var_2, b)
	) `HappyStk` happyRest}}

happyReduce_89 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_89 = happySpecReduce_3  29# happyReduction_89
happyReduction_89 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { happy_var_1 -> 
	case happyOut15 happy_x_2 of { (HappyWrap15 happy_var_2) -> 
	case happyOutTok happy_x_3 of { happy_var_3 -> 
	happyIn33
		 (return (Right (withSourceNote happy_var_1 happy_var_3 happy_var_2))
	)}}}

happyReduce_90 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_90 = happySpecReduce_3  29# happyReduction_90
happyReduction_90 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_2 of { (L _ (CmmT_Name        happy_var_2)) -> 
	happyIn33
		 (do l <- lookupLabel happy_var_2; return (Left l)
	)}

happyReduce_91 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_91 = happySpecReduce_1  30# happyReduction_91
happyReduction_91 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Int         happy_var_1)) -> 
	happyIn34
		 ([ happy_var_1 ]
	)}

happyReduce_92 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_92 = happySpecReduce_3  30# happyReduction_92
happyReduction_92 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Int         happy_var_1)) -> 
	case happyOut34 happy_x_3 of { (HappyWrap34 happy_var_3) -> 
	happyIn34
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_93 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_93 = happyReduce 5# 31# happyReduction_93
happyReduction_93 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_3 of { happy_var_3 -> 
	case happyOut15 happy_x_4 of { (HappyWrap15 happy_var_4) -> 
	case happyOutTok happy_x_5 of { happy_var_5 -> 
	happyIn35
		 (Just (withSourceNote happy_var_3 happy_var_5 happy_var_4)
	) `HappyStk` happyRest}}}

happyReduce_94 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_94 = happySpecReduce_0  31# happyReduction_94
happyReduction_94  =  happyIn35
		 (Nothing
	)

happyReduce_95 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_95 = happySpecReduce_0  32# happyReduction_95
happyReduction_95  =  happyIn36
		 (return ()
	)

happyReduce_96 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_96 = happyReduce 4# 32# happyReduction_96
happyReduction_96 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOutTok happy_x_2 of { happy_var_2 -> 
	case happyOut15 happy_x_3 of { (HappyWrap15 happy_var_3) -> 
	case happyOutTok happy_x_4 of { happy_var_4 -> 
	happyIn36
		 (withSourceNote happy_var_2 happy_var_4 happy_var_3
	) `HappyStk` happyRest}}}

happyReduce_97 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_97 = happyReduce 5# 33# happyReduction_97
happyReduction_97 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = happyIn37
		 (Just True
	) `HappyStk` happyRest

happyReduce_98 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_98 = happyReduce 5# 33# happyReduction_98
happyReduction_98 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = happyIn37
		 (Just False
	) `HappyStk` happyRest

happyReduce_99 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_99 = happySpecReduce_0  33# happyReduction_99
happyReduction_99  =  happyIn37
		 (Nothing
	)

happyReduce_100 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_100 = happySpecReduce_3  34# happyReduction_100
happyReduction_100 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Quot [happy_var_1,happy_var_3]
	)}}

happyReduce_101 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_101 = happySpecReduce_3  34# happyReduction_101
happyReduction_101 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Mul [happy_var_1,happy_var_3]
	)}}

happyReduce_102 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_102 = happySpecReduce_3  34# happyReduction_102
happyReduction_102 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Rem [happy_var_1,happy_var_3]
	)}}

happyReduce_103 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_103 = happySpecReduce_3  34# happyReduction_103
happyReduction_103 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Sub [happy_var_1,happy_var_3]
	)}}

happyReduce_104 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_104 = happySpecReduce_3  34# happyReduction_104
happyReduction_104 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Add [happy_var_1,happy_var_3]
	)}}

happyReduce_105 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_105 = happySpecReduce_3  34# happyReduction_105
happyReduction_105 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Shr [happy_var_1,happy_var_3]
	)}}

happyReduce_106 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_106 = happySpecReduce_3  34# happyReduction_106
happyReduction_106 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Shl [happy_var_1,happy_var_3]
	)}}

happyReduce_107 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_107 = happySpecReduce_3  34# happyReduction_107
happyReduction_107 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_And [happy_var_1,happy_var_3]
	)}}

happyReduce_108 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_108 = happySpecReduce_3  34# happyReduction_108
happyReduction_108 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Xor [happy_var_1,happy_var_3]
	)}}

happyReduce_109 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_109 = happySpecReduce_3  34# happyReduction_109
happyReduction_109 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Or [happy_var_1,happy_var_3]
	)}}

happyReduce_110 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_110 = happySpecReduce_3  34# happyReduction_110
happyReduction_110 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Ge [happy_var_1,happy_var_3]
	)}}

happyReduce_111 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_111 = happySpecReduce_3  34# happyReduction_111
happyReduction_111 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Gt [happy_var_1,happy_var_3]
	)}}

happyReduce_112 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_112 = happySpecReduce_3  34# happyReduction_112
happyReduction_112 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Le [happy_var_1,happy_var_3]
	)}}

happyReduce_113 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_113 = happySpecReduce_3  34# happyReduction_113
happyReduction_113 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_U_Lt [happy_var_1,happy_var_3]
	)}}

happyReduce_114 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_114 = happySpecReduce_3  34# happyReduction_114
happyReduction_114 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Ne [happy_var_1,happy_var_3]
	)}}

happyReduce_115 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_115 = happySpecReduce_3  34# happyReduction_115
happyReduction_115 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn38
		 (mkMachOp MO_Eq [happy_var_1,happy_var_3]
	)}}

happyReduce_116 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_116 = happySpecReduce_2  34# happyReduction_116
happyReduction_116 happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	happyIn38
		 (mkMachOp MO_Not [happy_var_2]
	)}

happyReduce_117 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_117 = happySpecReduce_2  34# happyReduction_117
happyReduction_117 happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	happyIn38
		 (mkMachOp MO_S_Neg [happy_var_2]
	)}

happyReduce_118 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_118 = happyMonadReduce 5# 34# happyReduction_118
happyReduction_118 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOut39 happy_x_1 of { (HappyWrap39 happy_var_1) -> 
	case happyOutTok happy_x_3 of { (L _ (CmmT_Name        happy_var_3)) -> 
	case happyOut39 happy_x_5 of { (HappyWrap39 happy_var_5) -> 
	( do { mo <- nameToMachOp happy_var_3 ;
                                                return (mkMachOp mo [happy_var_1,happy_var_5]) })}}})
	) (\r -> happyReturn (happyIn38 r))

happyReduce_119 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_119 = happySpecReduce_1  34# happyReduction_119
happyReduction_119 happy_x_1
	 =  case happyOut39 happy_x_1 of { (HappyWrap39 happy_var_1) -> 
	happyIn38
		 (happy_var_1
	)}

happyReduce_120 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_120 = happySpecReduce_2  35# happyReduction_120
happyReduction_120 happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Int         happy_var_1)) -> 
	case happyOut40 happy_x_2 of { (HappyWrap40 happy_var_2) -> 
	happyIn39
		 (return (CmmLit (CmmInt happy_var_1 (typeWidth happy_var_2)))
	)}}

happyReduce_121 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_121 = happySpecReduce_2  35# happyReduction_121
happyReduction_121 happy_x_2
	happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Float       happy_var_1)) -> 
	case happyOut40 happy_x_2 of { (HappyWrap40 happy_var_2) -> 
	happyIn39
		 (return (CmmLit (CmmFloat happy_var_1 (typeWidth happy_var_2)))
	)}}

happyReduce_122 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_122 = happySpecReduce_1  35# happyReduction_122
happyReduction_122 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_String      happy_var_1)) -> 
	happyIn39
		 (do s <- code (newStringCLit happy_var_1);
                                      return (CmmLit s)
	)}

happyReduce_123 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_123 = happySpecReduce_1  35# happyReduction_123
happyReduction_123 happy_x_1
	 =  case happyOut46 happy_x_1 of { (HappyWrap46 happy_var_1) -> 
	happyIn39
		 (happy_var_1
	)}

happyReduce_124 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_124 = happyReduce 4# 35# happyReduction_124
happyReduction_124 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut56 happy_x_1 of { (HappyWrap56 happy_var_1) -> 
	case happyOut38 happy_x_3 of { (HappyWrap38 happy_var_3) -> 
	happyIn39
		 (do e <- happy_var_3; return (CmmLoad e happy_var_1)
	) `HappyStk` happyRest}}

happyReduce_125 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_125 = happyMonadReduce 5# 35# happyReduction_125
happyReduction_125 (happy_x_5 `HappyStk`
	happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_2 of { (L _ (CmmT_Name        happy_var_2)) -> 
	case happyOut44 happy_x_4 of { (HappyWrap44 happy_var_4) -> 
	( exprOp happy_var_2 happy_var_4)}})
	) (\r -> happyReturn (happyIn39 r))

happyReduce_126 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_126 = happySpecReduce_3  35# happyReduction_126
happyReduction_126 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_2 of { (HappyWrap38 happy_var_2) -> 
	happyIn39
		 (happy_var_2
	)}

happyReduce_127 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_127 = happyMonadReduce 0# 36# happyReduction_127
happyReduction_127 (happyRest) tk
	 = happyThen ((( do dflags <- getDynFlags; return $ bWord dflags))
	) (\r -> happyReturn (happyIn40 r))

happyReduce_128 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_128 = happySpecReduce_2  36# happyReduction_128
happyReduction_128 happy_x_2
	happy_x_1
	 =  case happyOut56 happy_x_2 of { (HappyWrap56 happy_var_2) -> 
	happyIn40
		 (happy_var_2
	)}

happyReduce_129 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_129 = happySpecReduce_0  37# happyReduction_129
happyReduction_129  =  happyIn41
		 ([]
	)

happyReduce_130 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_130 = happySpecReduce_1  37# happyReduction_130
happyReduction_130 happy_x_1
	 =  case happyOut42 happy_x_1 of { (HappyWrap42 happy_var_1) -> 
	happyIn41
		 (happy_var_1
	)}

happyReduce_131 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_131 = happySpecReduce_1  38# happyReduction_131
happyReduction_131 happy_x_1
	 =  case happyOut43 happy_x_1 of { (HappyWrap43 happy_var_1) -> 
	happyIn42
		 ([happy_var_1]
	)}

happyReduce_132 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_132 = happySpecReduce_3  38# happyReduction_132
happyReduction_132 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut43 happy_x_1 of { (HappyWrap43 happy_var_1) -> 
	case happyOut42 happy_x_3 of { (HappyWrap42 happy_var_3) -> 
	happyIn42
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_133 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_133 = happySpecReduce_1  39# happyReduction_133
happyReduction_133 happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	happyIn43
		 (do e <- happy_var_1;
                                             return (e, inferCmmHint e)
	)}

happyReduce_134 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_134 = happyMonadReduce 2# 39# happyReduction_134
happyReduction_134 (happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOutTok happy_x_2 of { (L _ (CmmT_String      happy_var_2)) -> 
	( do h <- parseCmmHint happy_var_2;
                                              return $ do
                                                e <- happy_var_1; return (e, h))}})
	) (\r -> happyReturn (happyIn43 r))

happyReduce_135 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_135 = happySpecReduce_0  40# happyReduction_135
happyReduction_135  =  happyIn44
		 ([]
	)

happyReduce_136 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_136 = happySpecReduce_1  40# happyReduction_136
happyReduction_136 happy_x_1
	 =  case happyOut45 happy_x_1 of { (HappyWrap45 happy_var_1) -> 
	happyIn44
		 (happy_var_1
	)}

happyReduce_137 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_137 = happySpecReduce_1  41# happyReduction_137
happyReduction_137 happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	happyIn45
		 ([ happy_var_1 ]
	)}

happyReduce_138 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_138 = happySpecReduce_3  41# happyReduction_138
happyReduction_138 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut38 happy_x_1 of { (HappyWrap38 happy_var_1) -> 
	case happyOut45 happy_x_3 of { (HappyWrap45 happy_var_3) -> 
	happyIn45
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_139 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_139 = happySpecReduce_1  42# happyReduction_139
happyReduction_139 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn46
		 (lookupName happy_var_1
	)}

happyReduce_140 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_140 = happySpecReduce_1  42# happyReduction_140
happyReduction_140 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_GlobalReg   happy_var_1)) -> 
	happyIn46
		 (return (CmmReg (CmmGlobal happy_var_1))
	)}

happyReduce_141 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_141 = happySpecReduce_0  43# happyReduction_141
happyReduction_141  =  happyIn47
		 ([]
	)

happyReduce_142 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_142 = happyReduce 4# 43# happyReduction_142
happyReduction_142 (happy_x_4 `HappyStk`
	happy_x_3 `HappyStk`
	happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest)
	 = case happyOut48 happy_x_2 of { (HappyWrap48 happy_var_2) -> 
	happyIn47
		 (happy_var_2
	) `HappyStk` happyRest}

happyReduce_143 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_143 = happySpecReduce_1  44# happyReduction_143
happyReduction_143 happy_x_1
	 =  case happyOut49 happy_x_1 of { (HappyWrap49 happy_var_1) -> 
	happyIn48
		 ([happy_var_1]
	)}

happyReduce_144 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_144 = happySpecReduce_2  44# happyReduction_144
happyReduction_144 happy_x_2
	happy_x_1
	 =  case happyOut49 happy_x_1 of { (HappyWrap49 happy_var_1) -> 
	happyIn48
		 ([happy_var_1]
	)}

happyReduce_145 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_145 = happySpecReduce_3  44# happyReduction_145
happyReduction_145 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut49 happy_x_1 of { (HappyWrap49 happy_var_1) -> 
	case happyOut48 happy_x_3 of { (HappyWrap48 happy_var_3) -> 
	happyIn48
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_146 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_146 = happySpecReduce_1  45# happyReduction_146
happyReduction_146 happy_x_1
	 =  case happyOut50 happy_x_1 of { (HappyWrap50 happy_var_1) -> 
	happyIn49
		 (do e <- happy_var_1; return (e, inferCmmHint (CmmReg (CmmLocal e)))
	)}

happyReduce_147 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_147 = happyMonadReduce 2# 45# happyReduction_147
happyReduction_147 (happy_x_2 `HappyStk`
	happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((case happyOutTok happy_x_1 of { (L _ (CmmT_String      happy_var_1)) -> 
	case happyOut50 happy_x_2 of { (HappyWrap50 happy_var_2) -> 
	( do h <- parseCmmHint happy_var_1;
                                      return $ do
                                         e <- happy_var_2; return (e,h))}})
	) (\r -> happyReturn (happyIn49 r))

happyReduce_148 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_148 = happySpecReduce_1  46# happyReduction_148
happyReduction_148 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn50
		 (do e <- lookupName happy_var_1;
                                     return $
                                       case e of
                                        CmmReg (CmmLocal r) -> r
                                        other -> pprPanic "CmmParse:" (ftext happy_var_1 <> text " not a local register")
	)}

happyReduce_149 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_149 = happySpecReduce_1  47# happyReduction_149
happyReduction_149 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_Name        happy_var_1)) -> 
	happyIn51
		 (do e <- lookupName happy_var_1;
                                     return $
                                       case e of
                                        CmmReg r -> r
                                        other -> pprPanic "CmmParse:" (ftext happy_var_1 <> text " not a register")
	)}

happyReduce_150 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_150 = happySpecReduce_1  47# happyReduction_150
happyReduction_150 happy_x_1
	 =  case happyOutTok happy_x_1 of { (L _ (CmmT_GlobalReg   happy_var_1)) -> 
	happyIn51
		 (return (CmmGlobal happy_var_1)
	)}

happyReduce_151 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_151 = happySpecReduce_0  48# happyReduction_151
happyReduction_151  =  happyIn52
		 (Nothing
	)

happyReduce_152 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_152 = happySpecReduce_3  48# happyReduction_152
happyReduction_152 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut53 happy_x_2 of { (HappyWrap53 happy_var_2) -> 
	happyIn52
		 (Just happy_var_2
	)}

happyReduce_153 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_153 = happySpecReduce_0  49# happyReduction_153
happyReduction_153  =  happyIn53
		 ([]
	)

happyReduce_154 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_154 = happySpecReduce_1  49# happyReduction_154
happyReduction_154 happy_x_1
	 =  case happyOut54 happy_x_1 of { (HappyWrap54 happy_var_1) -> 
	happyIn53
		 (happy_var_1
	)}

happyReduce_155 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_155 = happySpecReduce_2  50# happyReduction_155
happyReduction_155 happy_x_2
	happy_x_1
	 =  case happyOut55 happy_x_1 of { (HappyWrap55 happy_var_1) -> 
	happyIn54
		 ([happy_var_1]
	)}

happyReduce_156 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_156 = happySpecReduce_1  50# happyReduction_156
happyReduction_156 happy_x_1
	 =  case happyOut55 happy_x_1 of { (HappyWrap55 happy_var_1) -> 
	happyIn54
		 ([happy_var_1]
	)}

happyReduce_157 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_157 = happySpecReduce_3  50# happyReduction_157
happyReduction_157 happy_x_3
	happy_x_2
	happy_x_1
	 =  case happyOut55 happy_x_1 of { (HappyWrap55 happy_var_1) -> 
	case happyOut54 happy_x_3 of { (HappyWrap54 happy_var_3) -> 
	happyIn54
		 (happy_var_1 : happy_var_3
	)}}

happyReduce_158 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_158 = happySpecReduce_2  51# happyReduction_158
happyReduction_158 happy_x_2
	happy_x_1
	 =  case happyOut56 happy_x_1 of { (HappyWrap56 happy_var_1) -> 
	case happyOutTok happy_x_2 of { (L _ (CmmT_Name        happy_var_2)) -> 
	happyIn55
		 (newLocal happy_var_1 happy_var_2
	)}}

happyReduce_159 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_159 = happySpecReduce_1  52# happyReduction_159
happyReduction_159 happy_x_1
	 =  happyIn56
		 (b8
	)

happyReduce_160 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_160 = happySpecReduce_1  52# happyReduction_160
happyReduction_160 happy_x_1
	 =  case happyOut57 happy_x_1 of { (HappyWrap57 happy_var_1) -> 
	happyIn56
		 (happy_var_1
	)}

happyReduce_161 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_161 = happySpecReduce_1  53# happyReduction_161
happyReduction_161 happy_x_1
	 =  happyIn57
		 (b16
	)

happyReduce_162 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_162 = happySpecReduce_1  53# happyReduction_162
happyReduction_162 happy_x_1
	 =  happyIn57
		 (b32
	)

happyReduce_163 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_163 = happySpecReduce_1  53# happyReduction_163
happyReduction_163 happy_x_1
	 =  happyIn57
		 (b64
	)

happyReduce_164 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_164 = happySpecReduce_1  53# happyReduction_164
happyReduction_164 happy_x_1
	 =  happyIn57
		 (b128
	)

happyReduce_165 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_165 = happySpecReduce_1  53# happyReduction_165
happyReduction_165 happy_x_1
	 =  happyIn57
		 (b256
	)

happyReduce_166 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_166 = happySpecReduce_1  53# happyReduction_166
happyReduction_166 happy_x_1
	 =  happyIn57
		 (b512
	)

happyReduce_167 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_167 = happySpecReduce_1  53# happyReduction_167
happyReduction_167 happy_x_1
	 =  happyIn57
		 (f32
	)

happyReduce_168 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_168 = happySpecReduce_1  53# happyReduction_168
happyReduction_168 happy_x_1
	 =  happyIn57
		 (f64
	)

happyReduce_169 :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )
happyReduce_169 = happyMonadReduce 1# 53# happyReduction_169
happyReduction_169 (happy_x_1 `HappyStk`
	happyRest) tk
	 = happyThen ((( do dflags <- getDynFlags; return $ gcWord dflags))
	) (\r -> happyReturn (happyIn57 r))

happyNewToken action sts stk
	= cmmlex(\tk -> 
	let cont i = happyDoAction i tk action sts stk in
	case tk of {
	L _ CmmT_EOF -> happyDoAction 77# tk action sts stk;
	L _ (CmmT_SpecChar ':') -> cont 1#;
	L _ (CmmT_SpecChar ';') -> cont 2#;
	L _ (CmmT_SpecChar '{') -> cont 3#;
	L _ (CmmT_SpecChar '}') -> cont 4#;
	L _ (CmmT_SpecChar '[') -> cont 5#;
	L _ (CmmT_SpecChar ']') -> cont 6#;
	L _ (CmmT_SpecChar '(') -> cont 7#;
	L _ (CmmT_SpecChar ')') -> cont 8#;
	L _ (CmmT_SpecChar '=') -> cont 9#;
	L _ (CmmT_SpecChar '`') -> cont 10#;
	L _ (CmmT_SpecChar '~') -> cont 11#;
	L _ (CmmT_SpecChar '/') -> cont 12#;
	L _ (CmmT_SpecChar '*') -> cont 13#;
	L _ (CmmT_SpecChar '%') -> cont 14#;
	L _ (CmmT_SpecChar '-') -> cont 15#;
	L _ (CmmT_SpecChar '+') -> cont 16#;
	L _ (CmmT_SpecChar '&') -> cont 17#;
	L _ (CmmT_SpecChar '^') -> cont 18#;
	L _ (CmmT_SpecChar '|') -> cont 19#;
	L _ (CmmT_SpecChar '>') -> cont 20#;
	L _ (CmmT_SpecChar '<') -> cont 21#;
	L _ (CmmT_SpecChar ',') -> cont 22#;
	L _ (CmmT_SpecChar '!') -> cont 23#;
	L _ (CmmT_DotDot) -> cont 24#;
	L _ (CmmT_DoubleColon) -> cont 25#;
	L _ (CmmT_Shr) -> cont 26#;
	L _ (CmmT_Shl) -> cont 27#;
	L _ (CmmT_Ge) -> cont 28#;
	L _ (CmmT_Le) -> cont 29#;
	L _ (CmmT_Eq) -> cont 30#;
	L _ (CmmT_Ne) -> cont 31#;
	L _ (CmmT_BoolAnd) -> cont 32#;
	L _ (CmmT_BoolOr) -> cont 33#;
	L _ (CmmT_True ) -> cont 34#;
	L _ (CmmT_False) -> cont 35#;
	L _ (CmmT_likely) -> cont 36#;
	L _ (CmmT_CLOSURE) -> cont 37#;
	L _ (CmmT_INFO_TABLE) -> cont 38#;
	L _ (CmmT_INFO_TABLE_RET) -> cont 39#;
	L _ (CmmT_INFO_TABLE_FUN) -> cont 40#;
	L _ (CmmT_INFO_TABLE_CONSTR) -> cont 41#;
	L _ (CmmT_INFO_TABLE_SELECTOR) -> cont 42#;
	L _ (CmmT_else) -> cont 43#;
	L _ (CmmT_export) -> cont 44#;
	L _ (CmmT_section) -> cont 45#;
	L _ (CmmT_goto) -> cont 46#;
	L _ (CmmT_if) -> cont 47#;
	L _ (CmmT_call) -> cont 48#;
	L _ (CmmT_jump) -> cont 49#;
	L _ (CmmT_foreign) -> cont 50#;
	L _ (CmmT_never) -> cont 51#;
	L _ (CmmT_prim) -> cont 52#;
	L _ (CmmT_reserve) -> cont 53#;
	L _ (CmmT_return) -> cont 54#;
	L _ (CmmT_returns) -> cont 55#;
	L _ (CmmT_import) -> cont 56#;
	L _ (CmmT_switch) -> cont 57#;
	L _ (CmmT_case) -> cont 58#;
	L _ (CmmT_default) -> cont 59#;
	L _ (CmmT_push) -> cont 60#;
	L _ (CmmT_unwind) -> cont 61#;
	L _ (CmmT_bits8) -> cont 62#;
	L _ (CmmT_bits16) -> cont 63#;
	L _ (CmmT_bits32) -> cont 64#;
	L _ (CmmT_bits64) -> cont 65#;
	L _ (CmmT_bits128) -> cont 66#;
	L _ (CmmT_bits256) -> cont 67#;
	L _ (CmmT_bits512) -> cont 68#;
	L _ (CmmT_float32) -> cont 69#;
	L _ (CmmT_float64) -> cont 70#;
	L _ (CmmT_gcptr) -> cont 71#;
	L _ (CmmT_GlobalReg   happy_dollar_dollar) -> cont 72#;
	L _ (CmmT_Name        happy_dollar_dollar) -> cont 73#;
	L _ (CmmT_String      happy_dollar_dollar) -> cont 74#;
	L _ (CmmT_Int         happy_dollar_dollar) -> cont 75#;
	L _ (CmmT_Float       happy_dollar_dollar) -> cont 76#;
	_ -> happyError' (tk, [])
	})

happyError_ explist 77# tk = happyError' (tk, explist)
happyError_ explist _ tk = happyError' (tk, explist)

happyThen :: () => PD a -> (a -> PD b) -> PD b
happyThen = (>>=)
happyReturn :: () => a -> PD a
happyReturn = (return)
happyParse :: () => Happy_GHC_Exts.Int# -> PD (HappyAbsSyn )

happyNewToken :: () => Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )

happyDoAction :: () => Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn )

happyReduceArr :: () => Happy_Data_Array.Array Int (Happy_GHC_Exts.Int# -> Located CmmToken -> Happy_GHC_Exts.Int# -> Happy_IntList -> HappyStk (HappyAbsSyn ) -> PD (HappyAbsSyn ))

happyThen1 :: () => PD a -> (a -> PD b) -> PD b
happyThen1 = happyThen
happyReturn1 :: () => a -> PD a
happyReturn1 = happyReturn
happyError' :: () => ((Located CmmToken), [String]) -> PD a
happyError' tk = (\(tokens, explist) -> happyError) tk
cmmParse = happySomeParser where
 happySomeParser = happyThen (happyParse 0#) (\x -> happyReturn (let {(HappyWrap4 x') = happyOut4 x} in x'))

happySeq = happyDoSeq


section :: String -> SectionType
section "text"      = Text
section "data"      = Data
section "rodata"    = ReadOnlyData
section "relrodata" = RelocatableReadOnlyData
section "bss"       = UninitialisedData
section s           = OtherSection s

mkString :: String -> CmmStatic
mkString s = CmmString (BS8.pack s)

-- |
-- Given an info table, decide what the entry convention for the proc
-- is.  That is, for an INFO_TABLE_RET we want the return convention,
-- otherwise it is a NativeNodeCall.
--
infoConv :: Maybe CmmInfoTable -> Convention
infoConv Nothing = NativeNodeCall
infoConv (Just info)
  | isStackRep (cit_rep info) = NativeReturn
  | otherwise                 = NativeNodeCall

-- mkMachOp infers the type of the MachOp from the type of its first
-- argument.  We assume that this is correct: for MachOps that don't have
-- symmetrical args (e.g. shift ops), the first arg determines the type of
-- the op.
mkMachOp :: (Width -> MachOp) -> [CmmParse CmmExpr] -> CmmParse CmmExpr
mkMachOp fn args = do
  dflags <- getDynFlags
  arg_exprs <- sequence args
  return (CmmMachOp (fn (typeWidth (cmmExprType dflags (head arg_exprs)))) arg_exprs)

getLit :: CmmExpr -> CmmLit
getLit (CmmLit l) = l
getLit (CmmMachOp (MO_S_Neg _) [CmmLit (CmmInt i r)])  = CmmInt (negate i) r
getLit _ = panic "invalid literal" -- TODO messy failure

nameToMachOp :: FastString -> PD (Width -> MachOp)
nameToMachOp name =
  case lookupUFM machOps name of
        Nothing -> fail ("unknown primitive " ++ unpackFS name)
        Just m  -> return m

exprOp :: FastString -> [CmmParse CmmExpr] -> PD (CmmParse CmmExpr)
exprOp name args_code = do
  dflags <- getDynFlags
  case lookupUFM (exprMacros dflags) name of
     Just f  -> return $ do
        args <- sequence args_code
        return (f args)
     Nothing -> do
        mo <- nameToMachOp name
        return $ mkMachOp mo args_code

exprMacros :: DynFlags -> UniqFM ([CmmExpr] -> CmmExpr)
exprMacros dflags = listToUFM [
  ( fsLit "ENTRY_CODE",   \ [x] -> entryCode dflags x ),
  ( fsLit "INFO_PTR",     \ [x] -> closureInfoPtr dflags x ),
  ( fsLit "STD_INFO",     \ [x] -> infoTable dflags x ),
  ( fsLit "FUN_INFO",     \ [x] -> funInfoTable dflags x ),
  ( fsLit "GET_ENTRY",    \ [x] -> entryCode dflags (closureInfoPtr dflags x) ),
  ( fsLit "GET_STD_INFO", \ [x] -> infoTable dflags (closureInfoPtr dflags x) ),
  ( fsLit "GET_FUN_INFO", \ [x] -> funInfoTable dflags (closureInfoPtr dflags x) ),
  ( fsLit "INFO_TYPE",    \ [x] -> infoTableClosureType dflags x ),
  ( fsLit "INFO_PTRS",    \ [x] -> infoTablePtrs dflags x ),
  ( fsLit "INFO_NPTRS",   \ [x] -> infoTableNonPtrs dflags x )
  ]

-- we understand a subset of C-- primitives:
machOps = listToUFM $
        map (\(x, y) -> (mkFastString x, y)) [
        ( "add",        MO_Add ),
        ( "sub",        MO_Sub ),
        ( "eq",         MO_Eq ),
        ( "ne",         MO_Ne ),
        ( "mul",        MO_Mul ),
        ( "neg",        MO_S_Neg ),
        ( "quot",       MO_S_Quot ),
        ( "rem",        MO_S_Rem ),
        ( "divu",       MO_U_Quot ),
        ( "modu",       MO_U_Rem ),

        ( "ge",         MO_S_Ge ),
        ( "le",         MO_S_Le ),
        ( "gt",         MO_S_Gt ),
        ( "lt",         MO_S_Lt ),

        ( "geu",        MO_U_Ge ),
        ( "leu",        MO_U_Le ),
        ( "gtu",        MO_U_Gt ),
        ( "ltu",        MO_U_Lt ),

        ( "and",        MO_And ),
        ( "or",         MO_Or ),
        ( "xor",        MO_Xor ),
        ( "com",        MO_Not ),
        ( "shl",        MO_Shl ),
        ( "shrl",       MO_U_Shr ),
        ( "shra",       MO_S_Shr ),

        ( "fadd",       MO_F_Add ),
        ( "fsub",       MO_F_Sub ),
        ( "fneg",       MO_F_Neg ),
        ( "fmul",       MO_F_Mul ),
        ( "fquot",      MO_F_Quot ),

        ( "feq",        MO_F_Eq ),
        ( "fne",        MO_F_Ne ),
        ( "fge",        MO_F_Ge ),
        ( "fle",        MO_F_Le ),
        ( "fgt",        MO_F_Gt ),
        ( "flt",        MO_F_Lt ),

        ( "lobits8",  flip MO_UU_Conv W8  ),
        ( "lobits16", flip MO_UU_Conv W16 ),
        ( "lobits32", flip MO_UU_Conv W32 ),
        ( "lobits64", flip MO_UU_Conv W64 ),

        ( "zx16",     flip MO_UU_Conv W16 ),
        ( "zx32",     flip MO_UU_Conv W32 ),
        ( "zx64",     flip MO_UU_Conv W64 ),

        ( "sx16",     flip MO_SS_Conv W16 ),
        ( "sx32",     flip MO_SS_Conv W32 ),
        ( "sx64",     flip MO_SS_Conv W64 ),

        ( "f2f32",    flip MO_FF_Conv W32 ),  -- TODO; rounding mode
        ( "f2f64",    flip MO_FF_Conv W64 ),  -- TODO; rounding mode
        ( "f2i8",     flip MO_FS_Conv W8 ),
        ( "f2i16",    flip MO_FS_Conv W16 ),
        ( "f2i32",    flip MO_FS_Conv W32 ),
        ( "f2i64",    flip MO_FS_Conv W64 ),
        ( "i2f32",    flip MO_SF_Conv W32 ),
        ( "i2f64",    flip MO_SF_Conv W64 )
        ]

callishMachOps :: UniqFM ([CmmExpr] -> (CallishMachOp, [CmmExpr]))
callishMachOps = listToUFM $
        map (\(x, y) -> (mkFastString x, y)) [
        ( "read_barrier", (MO_ReadBarrier,)),
        ( "write_barrier", (MO_WriteBarrier,)),
        ( "memcpy", memcpyLikeTweakArgs MO_Memcpy ),
        ( "memset", memcpyLikeTweakArgs MO_Memset ),
        ( "memmove", memcpyLikeTweakArgs MO_Memmove ),
        ( "memcmp", memcpyLikeTweakArgs MO_Memcmp ),

        ("prefetch0", (MO_Prefetch_Data 0,)),
        ("prefetch1", (MO_Prefetch_Data 1,)),
        ("prefetch2", (MO_Prefetch_Data 2,)),
        ("prefetch3", (MO_Prefetch_Data 3,)),

        ( "popcnt8",  (MO_PopCnt W8,)),
        ( "popcnt16", (MO_PopCnt W16,)),
        ( "popcnt32", (MO_PopCnt W32,)),
        ( "popcnt64", (MO_PopCnt W64,)),

        ( "pdep8",  (MO_Pdep W8,)),
        ( "pdep16", (MO_Pdep W16,)),
        ( "pdep32", (MO_Pdep W32,)),
        ( "pdep64", (MO_Pdep W64,)),

        ( "pext8",  (MO_Pext W8,)),
        ( "pext16", (MO_Pext W16,)),
        ( "pext32", (MO_Pext W32,)),
        ( "pext64", (MO_Pext W64,)),

        ( "cmpxchg8",  (MO_Cmpxchg W8,)),
        ( "cmpxchg16", (MO_Cmpxchg W16,)),
        ( "cmpxchg32", (MO_Cmpxchg W32,)),
        ( "cmpxchg64", (MO_Cmpxchg W64,))

        -- ToDo: the rest, maybe
        -- edit: which rest?
        -- also: how do we tell CMM Lint how to type check callish macops?
    ]
  where
    memcpyLikeTweakArgs :: (Int -> CallishMachOp) -> [CmmExpr] -> (CallishMachOp, [CmmExpr])
    memcpyLikeTweakArgs op [] = pgmError "memcpy-like function requires at least one argument"
    memcpyLikeTweakArgs op args@(_:_) =
        (op align, args')
      where
        args' = init args
        align = case last args of
          CmmLit (CmmInt alignInteger _) -> fromInteger alignInteger
          e -> pprPgmError "Non-constant alignment in memcpy-like function:" (ppr e)
        -- The alignment of memcpy-ish operations must be a
        -- compile-time constant. We verify this here, passing it around
        -- in the MO_* constructor. In order to do this, however, we
        -- must intercept the arguments in primCall.

parseSafety :: String -> PD Safety
parseSafety "safe"   = return PlaySafe
parseSafety "unsafe" = return PlayRisky
parseSafety "interruptible" = return PlayInterruptible
parseSafety str      = fail ("unrecognised safety: " ++ str)

parseCmmHint :: String -> PD ForeignHint
parseCmmHint "ptr"    = return AddrHint
parseCmmHint "signed" = return SignedHint
parseCmmHint str      = fail ("unrecognised hint: " ++ str)

-- labels are always pointers, so we might as well infer the hint
inferCmmHint :: CmmExpr -> ForeignHint
inferCmmHint (CmmLit (CmmLabel _)) = AddrHint
inferCmmHint (CmmReg (CmmGlobal g)) | isPtrGlobalReg g = AddrHint
inferCmmHint _ = NoHint

isPtrGlobalReg Sp                    = True
isPtrGlobalReg SpLim                 = True
isPtrGlobalReg Hp                    = True
isPtrGlobalReg HpLim                 = True
isPtrGlobalReg CCCS                  = True
isPtrGlobalReg CurrentTSO            = True
isPtrGlobalReg CurrentNursery        = True
isPtrGlobalReg (VanillaReg _ VGcPtr) = True
isPtrGlobalReg _                     = False

happyError :: PD a
happyError = PD $ \_ s -> unP srcParseFail s

-- -----------------------------------------------------------------------------
-- Statement-level macros

stmtMacro :: FastString -> [CmmParse CmmExpr] -> PD (CmmParse ())
stmtMacro fun args_code = do
  case lookupUFM stmtMacros fun of
    Nothing -> fail ("unknown macro: " ++ unpackFS fun)
    Just fcode -> return $ do
        args <- sequence args_code
        code (fcode args)

stmtMacros :: UniqFM ([CmmExpr] -> FCode ())
stmtMacros = listToUFM [
  ( fsLit "CCS_ALLOC",             \[words,ccs]  -> profAlloc words ccs ),
  ( fsLit "ENTER_CCS_THUNK",       \[e] -> enterCostCentreThunk e ),

  ( fsLit "CLOSE_NURSERY",         \[]  -> emitCloseNursery ),
  ( fsLit "OPEN_NURSERY",          \[]  -> emitOpenNursery ),

  -- completely generic heap and stack checks, for use in high-level cmm.
  ( fsLit "HP_CHK_GEN",            \[bytes] ->
                                      heapStackCheckGen Nothing (Just bytes) ),
  ( fsLit "STK_CHK_GEN",           \[] ->
                                      heapStackCheckGen (Just (CmmLit CmmHighStackMark)) Nothing ),

  -- A stack check for a fixed amount of stack.  Sounds a bit strange, but
  -- we use the stack for a bit of temporary storage in a couple of primops
  ( fsLit "STK_CHK_GEN_N",         \[bytes] ->
                                      heapStackCheckGen (Just bytes) Nothing ),

  -- A stack check on entry to a thunk, where the argument is the thunk pointer.
  ( fsLit "STK_CHK_NP"   ,         \[node] -> entryHeapCheck' False node 0 [] (return ())),

  ( fsLit "LOAD_THREAD_STATE",     \[] -> emitLoadThreadState ),
  ( fsLit "SAVE_THREAD_STATE",     \[] -> emitSaveThreadState ),

  ( fsLit "SAVE_REGS",             \[] -> emitSaveRegs ),
  ( fsLit "RESTORE_REGS",          \[] -> emitRestoreRegs ),

  ( fsLit "LDV_ENTER",             \[e] -> ldvEnter e ),
  ( fsLit "LDV_RECORD_CREATE",     \[e] -> ldvRecordCreate e ),

  ( fsLit "PUSH_UPD_FRAME",        \[sp,e] -> emitPushUpdateFrame sp e ),
  ( fsLit "SET_HDR",               \[ptr,info,ccs] ->
                                        emitSetDynHdr ptr info ccs ),
  ( fsLit "TICK_ALLOC_PRIM",       \[hdr,goods,slop] ->
                                        tickyAllocPrim hdr goods slop ),
  ( fsLit "TICK_ALLOC_PAP",        \[goods,slop] ->
                                        tickyAllocPAP goods slop ),
  ( fsLit "TICK_ALLOC_UP_THK",     \[goods,slop] ->
                                        tickyAllocThunk goods slop ),
  ( fsLit "UPD_BH_UPDATABLE",      \[reg] -> emitBlackHoleCode reg )
 ]

emitPushUpdateFrame :: CmmExpr -> CmmExpr -> FCode ()
emitPushUpdateFrame sp e = do
  dflags <- getDynFlags
  emitUpdateFrame dflags sp mkUpdInfoLabel e

pushStackFrame :: [CmmParse CmmExpr] -> CmmParse () -> CmmParse ()
pushStackFrame fields body = do
  dflags <- getDynFlags
  exprs <- sequence fields
  updfr_off <- getUpdFrameOff
  let (new_updfr_off, _, g) = copyOutOflow dflags NativeReturn Ret Old
                                           [] updfr_off exprs
  emit g
  withUpdFrameOff new_updfr_off body

reserveStackFrame
  :: CmmParse CmmExpr
  -> CmmParse CmmReg
  -> CmmParse ()
  -> CmmParse ()
reserveStackFrame psize preg body = do
  dflags <- getDynFlags
  old_updfr_off <- getUpdFrameOff
  reg <- preg
  esize <- psize
  let size = case constantFoldExpr dflags esize of
               CmmLit (CmmInt n _) -> n
               _other -> pprPanic "CmmParse: not a compile-time integer: "
                            (ppr esize)
  let frame = old_updfr_off + wORD_SIZE dflags * fromIntegral size
  emitAssign reg (CmmStackSlot Old frame)
  withUpdFrameOff frame body

profilingInfo dflags desc_str ty_str
  = if not (gopt Opt_SccProfilingOn dflags)
    then NoProfilingInfo
    else ProfilingInfo (BS8.pack desc_str) (BS8.pack ty_str)

staticClosure :: UnitId -> FastString -> FastString -> [CmmLit] -> CmmParse ()
staticClosure pkg cl_label info payload
  = do dflags <- getDynFlags
       let lits = mkStaticClosure dflags (mkCmmInfoLabel pkg info) dontCareCCS payload [] [] []
       code $ emitDataLits (mkCmmDataLabel pkg (NeedExternDecl True) cl_label) lits

foreignCall
        :: String
        -> [CmmParse (LocalReg, ForeignHint)]
        -> CmmParse CmmExpr
        -> [CmmParse (CmmExpr, ForeignHint)]
        -> Safety
        -> CmmReturnInfo
        -> PD (CmmParse ())
foreignCall conv_string results_code expr_code args_code safety ret
  = do  conv <- case conv_string of
          "C" -> return CCallConv
          "stdcall" -> return StdCallConv
          _ -> fail ("unknown calling convention: " ++ conv_string)
        return $ do
          dflags <- getDynFlags
          results <- sequence results_code
          expr <- expr_code
          args <- sequence args_code
          let
                  expr' = adjCallTarget dflags conv expr args
                  (arg_exprs, arg_hints) = unzip args
                  (res_regs,  res_hints) = unzip results
                  res_cmm_tys = zip (map localRegType res_regs) res_hints
                  arg_cmm_tys = zip (map (cmmExprType dflags) arg_exprs) arg_hints
                  res_rep :: (CmmType, ForeignHint) -> PrimRep
                  res_rep (_, AddrHint)                       = AddrRep
                  res_rep (t, _)          | isGcPtrType t     = Word64Rep
                  res_rep (t, SignedHint) | t `cmmEqType` b8  = Int8Rep
                  res_rep (t, SignedHint) | t `cmmEqType` b16 = Int16Rep
                  res_rep (t, SignedHint) | t `cmmEqType` b32 = Int32Rep
                  res_rep (t, SignedHint) | t `cmmEqType` b64 = Int64Rep
                  res_rep (t, NoHint)     | t `cmmEqType` b8  = Word8Rep
                  res_rep (t, NoHint)     | t `cmmEqType` b16 = Word16Rep
                  res_rep (t, NoHint)     | t `cmmEqType` b32 = Word32Rep
                  res_rep (t, NoHint)     | t `cmmEqType` b64 = Word64Rep
                  res_rep (t, _)          | t `cmmEqType` f32 = FloatRep
                  res_rep (t, _)          | t `cmmEqType` f64 = DoubleRep

                  ret_rep = case (map res_rep res_cmm_tys) of
                    [] -> VoidRep
                    [r] -> r
                    x -> (panic $ show x)
                  fc = ForeignConvention conv arg_hints res_hints ret ret_rep (map res_rep arg_cmm_tys)
                  target = ForeignTarget expr' fc
          _ <- code $ emitForeignCall safety res_regs target arg_exprs
          return ()


doReturn :: [CmmParse CmmExpr] -> CmmParse ()
doReturn exprs_code = do
  dflags <- getDynFlags
  exprs <- sequence exprs_code
  updfr_off <- getUpdFrameOff
  emit (mkReturnSimple dflags exprs updfr_off)

mkReturnSimple  :: DynFlags -> [CmmActual] -> UpdFrameOffset -> CmmAGraph
mkReturnSimple dflags actuals updfr_off =
  mkReturn dflags e actuals updfr_off
  where e = entryCode dflags (CmmLoad (CmmStackSlot Old updfr_off)
                             (gcWord dflags))

doRawJump :: CmmParse CmmExpr -> [GlobalReg] -> CmmParse ()
doRawJump expr_code vols = do
  dflags <- getDynFlags
  expr <- expr_code
  updfr_off <- getUpdFrameOff
  emit (mkRawJump dflags expr updfr_off vols)

doJumpWithStack :: CmmParse CmmExpr -> [CmmParse CmmExpr]
                -> [CmmParse CmmExpr] -> CmmParse ()
doJumpWithStack expr_code stk_code args_code = do
  dflags <- getDynFlags
  expr <- expr_code
  stk_args <- sequence stk_code
  args <- sequence args_code
  updfr_off <- getUpdFrameOff
  emit (mkJumpExtra dflags NativeNodeCall expr args updfr_off stk_args)

doCall :: CmmParse CmmExpr -> [CmmParse LocalReg] -> [CmmParse CmmExpr]
       -> CmmParse ()
doCall expr_code res_code args_code = do
  dflags <- getDynFlags
  expr <- expr_code
  args <- sequence args_code
  ress <- sequence res_code
  updfr_off <- getUpdFrameOff
  c <- code $ mkCall expr (NativeNodeCall,NativeReturn) ress args updfr_off []
  emit c

adjCallTarget :: DynFlags -> CCallConv -> CmmExpr -> [(CmmExpr, ForeignHint) ]
              -> CmmExpr
-- On Windows, we have to add the '@N' suffix to the label when making
-- a call with the stdcall calling convention.
adjCallTarget dflags StdCallConv (CmmLit (CmmLabel lbl)) args
 | platformOS (targetPlatform dflags) == OSMinGW32
  = CmmLit (CmmLabel (addLabelSize lbl (sum (map size args))))
  where size (e, _) = max (wORD_SIZE dflags) (widthInBytes (typeWidth (cmmExprType dflags e)))
                 -- c.f. CgForeignCall.emitForeignCall
adjCallTarget _ _ expr _
  = expr

primCall
        :: [CmmParse (CmmFormal, ForeignHint)]
        -> FastString
        -> [CmmParse CmmExpr]
        -> PD (CmmParse ())
primCall results_code name args_code
  = case lookupUFM callishMachOps name of
        Nothing -> fail ("unknown primitive " ++ unpackFS name)
        Just f  -> return $ do
                results <- sequence results_code
                args <- sequence args_code
                let (p, args') = f args
                code (emitPrimCall (map fst results) p args')

doStore :: CmmType -> CmmParse CmmExpr  -> CmmParse CmmExpr -> CmmParse ()
doStore rep addr_code val_code
  = do dflags <- getDynFlags
       addr <- addr_code
       val <- val_code
        -- if the specified store type does not match the type of the expr
        -- on the rhs, then we insert a coercion that will cause the type
        -- mismatch to be flagged by cmm-lint.  If we don't do this, then
        -- the store will happen at the wrong type, and the error will not
        -- be noticed.
       let val_width = typeWidth (cmmExprType dflags val)
           rep_width = typeWidth rep
       let coerce_val
                | val_width /= rep_width = CmmMachOp (MO_UU_Conv val_width rep_width) [val]
                | otherwise              = val
       emitStore addr coerce_val

-- -----------------------------------------------------------------------------
-- If-then-else and boolean expressions

data BoolExpr
  = BoolExpr `BoolAnd` BoolExpr
  | BoolExpr `BoolOr`  BoolExpr
  | BoolNot BoolExpr
  | BoolTest CmmExpr

-- ToDo: smart constructors which simplify the boolean expression.

cmmIfThenElse cond then_part else_part likely = do
     then_id <- newBlockId
     join_id <- newBlockId
     c <- cond
     emitCond c then_id likely
     else_part
     emit (mkBranch join_id)
     emitLabel then_id
     then_part
     -- fall through to join
     emitLabel join_id

cmmRawIf cond then_id likely = do
    c <- cond
    emitCond c then_id likely

-- 'emitCond cond true_id'  emits code to test whether the cond is true,
-- branching to true_id if so, and falling through otherwise.
emitCond (BoolTest e) then_id likely = do
  else_id <- newBlockId
  emit (mkCbranch e then_id else_id likely)
  emitLabel else_id
emitCond (BoolNot (BoolTest (CmmMachOp op args))) then_id likely
  | Just op' <- maybeInvertComparison op
  = emitCond (BoolTest (CmmMachOp op' args)) then_id (not <$> likely)
emitCond (BoolNot e) then_id likely = do
  else_id <- newBlockId
  emitCond e else_id likely
  emit (mkBranch then_id)
  emitLabel else_id
emitCond (e1 `BoolOr` e2) then_id likely = do
  emitCond e1 then_id likely
  emitCond e2 then_id likely
emitCond (e1 `BoolAnd` e2) then_id likely = do
        -- we'd like to invert one of the conditionals here to avoid an
        -- extra branch instruction, but we can't use maybeInvertComparison
        -- here because we can't look too closely at the expression since
        -- we're in a loop.
  and_id <- newBlockId
  else_id <- newBlockId
  emitCond e1 and_id likely
  emit (mkBranch else_id)
  emitLabel and_id
  emitCond e2 then_id likely
  emitLabel else_id

-- -----------------------------------------------------------------------------
-- Source code notes

-- | Generate a source note spanning from "a" to "b" (inclusive), then
-- proceed with parsing. This allows debugging tools to reason about
-- locations in Cmm code.
withSourceNote :: Located a -> Located b -> CmmParse c -> CmmParse c
withSourceNote a b parse = do
  name <- getName
  case combineSrcSpans (getLoc a) (getLoc b) of
    RealSrcSpan span -> code (emitTick (SourceNote span name)) >> parse
    _other           -> parse

-- -----------------------------------------------------------------------------
-- Table jumps

-- We use a simplified form of C-- switch statements for now.  A
-- switch statement always compiles to a table jump.  Each arm can
-- specify a list of values (not ranges), and there can be a single
-- default branch.  The range of the table is given either by the
-- optional range on the switch (eg. switch [0..7] {...}), or by
-- the minimum/maximum values from the branches.

doSwitch :: Maybe (Integer,Integer)
         -> CmmParse CmmExpr
         -> [([Integer],Either BlockId (CmmParse ()))]
         -> Maybe (CmmParse ()) -> CmmParse ()
doSwitch mb_range scrut arms deflt
   = do
        -- Compile code for the default branch
        dflt_entry <-
                case deflt of
                  Nothing -> return Nothing
                  Just e  -> do b <- forkLabelledCode e; return (Just b)

        -- Compile each case branch
        table_entries <- mapM emitArm arms
        let table = M.fromList (concat table_entries)

        dflags <- getDynFlags
        let range = fromMaybe (0, tARGET_MAX_WORD dflags) mb_range

        expr <- scrut
        -- ToDo: check for out of range and jump to default if necessary
        emit $ mkSwitch expr (mkSwitchTargets False range dflt_entry table)
   where
        emitArm :: ([Integer],Either BlockId (CmmParse ())) -> CmmParse [(Integer,BlockId)]
        emitArm (ints,Left blockid) = return [ (i,blockid) | i <- ints ]
        emitArm (ints,Right code) = do
           blockid <- forkLabelledCode code
           return [ (i,blockid) | i <- ints ]

forkLabelledCode :: CmmParse () -> CmmParse BlockId
forkLabelledCode p = do
  (_,ag) <- getCodeScoped p
  l <- newBlockId
  emitOutOfLine l ag
  return l

-- -----------------------------------------------------------------------------
-- Putting it all together

-- The initial environment: we define some constants that the compiler
-- knows about here.
initEnv :: DynFlags -> Env
initEnv dflags = listToUFM [
  ( fsLit "SIZEOF_StgHeader",
    VarN (CmmLit (CmmInt (fromIntegral (fixedHdrSize dflags)) (wordWidth dflags)) )),
  ( fsLit "SIZEOF_StgInfoTable",
    VarN (CmmLit (CmmInt (fromIntegral (stdInfoTableSizeB dflags)) (wordWidth dflags)) ))
  ]

parseCmmFile :: DynFlags -> FilePath -> IO (Messages, Maybe CmmGroup)
parseCmmFile dflags filename = withTiming dflags (text "ParseCmm"<+>brackets (text filename)) (\_ -> ()) $ do
  buf <- hGetStringBuffer filename
  let
        init_loc = mkRealSrcLoc (mkFastString filename) 1 1
        init_state = (mkPState dflags buf init_loc) { lex_state = [0] }
                -- reset the lex_state: the Lexer monad leaves some stuff
                -- in there we don't want.
  case unPD cmmParse dflags init_state of
    PFailed pst ->
        return (getMessages pst dflags, Nothing)
    POk pst code -> do
        st <- initC
        let fcode = getCmm $ unEC code "global" (initEnv dflags) [] >> return ()
            (cmm,_) = runC dflags no_module st fcode
        let ms = getMessages pst dflags
        if (errorsFound dflags ms)
         then return (ms, Nothing)
         else return (ms, Just cmm)
  where
        no_module = panic "parseCmmFile: no module"
{-# LINE 1 "templates/GenericTemplate.hs" #-}
-- $Id: GenericTemplate.hs,v 1.26 2005/01/14 14:47:22 simonmar Exp $













-- Do not remove this comment. Required to fix CPP parsing when using GCC and a clang-compiled alex.
#if __GLASGOW_HASKELL__ > 706
#define LT(n,m) ((Happy_GHC_Exts.tagToEnum# (n Happy_GHC_Exts.<# m)) :: Bool)
#define GTE(n,m) ((Happy_GHC_Exts.tagToEnum# (n Happy_GHC_Exts.>=# m)) :: Bool)
#define EQ(n,m) ((Happy_GHC_Exts.tagToEnum# (n Happy_GHC_Exts.==# m)) :: Bool)
#else
#define LT(n,m) (n Happy_GHC_Exts.<# m)
#define GTE(n,m) (n Happy_GHC_Exts.>=# m)
#define EQ(n,m) (n Happy_GHC_Exts.==# m)
#endif



















data Happy_IntList = HappyCons Happy_GHC_Exts.Int# Happy_IntList








































infixr 9 `HappyStk`
data HappyStk a = HappyStk a (HappyStk a)

-----------------------------------------------------------------------------
-- starting the parse

happyParse start_state = happyNewToken start_state notHappyAtAll notHappyAtAll

-----------------------------------------------------------------------------
-- Accepting the parse

-- If the current token is ERROR_TOK, it means we've just accepted a partial
-- parse (a %partial parser).  We must ignore the saved token on the top of
-- the stack in this case.
happyAccept 0# tk st sts (_ `HappyStk` ans `HappyStk` _) =
        happyReturn1 ans
happyAccept j tk st sts (HappyStk ans _) = 
        (happyTcHack j (happyTcHack st)) (happyReturn1 ans)

-----------------------------------------------------------------------------
-- Arrays only: do the next action



happyDoAction i tk st
        = {- nothing -}
          case action of
                0#           -> {- nothing -}
                                     happyFail (happyExpListPerState ((Happy_GHC_Exts.I# (st)) :: Int)) i tk st
                -1#          -> {- nothing -}
                                     happyAccept i tk st
                n | LT(n,(0# :: Happy_GHC_Exts.Int#)) -> {- nothing -}
                                                   (happyReduceArr Happy_Data_Array.! rule) i tk st
                                                   where rule = (Happy_GHC_Exts.I# ((Happy_GHC_Exts.negateInt# ((n Happy_GHC_Exts.+# (1# :: Happy_GHC_Exts.Int#))))))
                n                 -> {- nothing -}
                                     happyShift new_state i tk st
                                     where new_state = (n Happy_GHC_Exts.-# (1# :: Happy_GHC_Exts.Int#))
   where off    = happyAdjustOffset (indexShortOffAddr happyActOffsets st)
         off_i  = (off Happy_GHC_Exts.+# i)
         check  = if GTE(off_i,(0# :: Happy_GHC_Exts.Int#))
                  then EQ(indexShortOffAddr happyCheck off_i, i)
                  else False
         action
          | check     = indexShortOffAddr happyTable off_i
          | otherwise = indexShortOffAddr happyDefActions st




indexShortOffAddr (HappyA# arr) off =
        Happy_GHC_Exts.narrow16Int# i
  where
        i = Happy_GHC_Exts.word2Int# (Happy_GHC_Exts.or# (Happy_GHC_Exts.uncheckedShiftL# high 8#) low)
        high = Happy_GHC_Exts.int2Word# (Happy_GHC_Exts.ord# (Happy_GHC_Exts.indexCharOffAddr# arr (off' Happy_GHC_Exts.+# 1#)))
        low  = Happy_GHC_Exts.int2Word# (Happy_GHC_Exts.ord# (Happy_GHC_Exts.indexCharOffAddr# arr off'))
        off' = off Happy_GHC_Exts.*# 2#




{-# INLINE happyLt #-}
happyLt x y = LT(x,y)


readArrayBit arr bit =
    Bits.testBit (Happy_GHC_Exts.I# (indexShortOffAddr arr ((unbox_int bit) `Happy_GHC_Exts.iShiftRA#` 4#))) (bit `mod` 16)
  where unbox_int (Happy_GHC_Exts.I# x) = x






data HappyAddr = HappyA# Happy_GHC_Exts.Addr#


-----------------------------------------------------------------------------
-- HappyState data type (not arrays)













-----------------------------------------------------------------------------
-- Shifting a token

happyShift new_state 0# tk st sts stk@(x `HappyStk` _) =
     let i = (case Happy_GHC_Exts.unsafeCoerce# x of { (Happy_GHC_Exts.I# (i)) -> i }) in
--     trace "shifting the error token" $
     happyDoAction i tk new_state (HappyCons (st) (sts)) (stk)

happyShift new_state i tk st sts stk =
     happyNewToken new_state (HappyCons (st) (sts)) ((happyInTok (tk))`HappyStk`stk)

-- happyReduce is specialised for the common cases.

happySpecReduce_0 i fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happySpecReduce_0 nt fn j tk st@((action)) sts stk
     = happyGoto nt j tk st (HappyCons (st) (sts)) (fn `HappyStk` stk)

happySpecReduce_1 i fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happySpecReduce_1 nt fn j tk _ sts@((HappyCons (st@(action)) (_))) (v1`HappyStk`stk')
     = let r = fn v1 in
       happySeq r (happyGoto nt j tk st sts (r `HappyStk` stk'))

happySpecReduce_2 i fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happySpecReduce_2 nt fn j tk _ (HappyCons (_) (sts@((HappyCons (st@(action)) (_))))) (v1`HappyStk`v2`HappyStk`stk')
     = let r = fn v1 v2 in
       happySeq r (happyGoto nt j tk st sts (r `HappyStk` stk'))

happySpecReduce_3 i fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happySpecReduce_3 nt fn j tk _ (HappyCons (_) ((HappyCons (_) (sts@((HappyCons (st@(action)) (_))))))) (v1`HappyStk`v2`HappyStk`v3`HappyStk`stk')
     = let r = fn v1 v2 v3 in
       happySeq r (happyGoto nt j tk st sts (r `HappyStk` stk'))

happyReduce k i fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happyReduce k nt fn j tk st sts stk
     = case happyDrop (k Happy_GHC_Exts.-# (1# :: Happy_GHC_Exts.Int#)) sts of
         sts1@((HappyCons (st1@(action)) (_))) ->
                let r = fn stk in  -- it doesn't hurt to always seq here...
                happyDoSeq r (happyGoto nt j tk st1 sts1 r)

happyMonadReduce k nt fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happyMonadReduce k nt fn j tk st sts stk =
      case happyDrop k (HappyCons (st) (sts)) of
        sts1@((HappyCons (st1@(action)) (_))) ->
          let drop_stk = happyDropStk k stk in
          happyThen1 (fn stk tk) (\r -> happyGoto nt j tk st1 sts1 (r `HappyStk` drop_stk))

happyMonad2Reduce k nt fn 0# tk st sts stk
     = happyFail [] 0# tk st sts stk
happyMonad2Reduce k nt fn j tk st sts stk =
      case happyDrop k (HappyCons (st) (sts)) of
        sts1@((HappyCons (st1@(action)) (_))) ->
         let drop_stk = happyDropStk k stk

             off = happyAdjustOffset (indexShortOffAddr happyGotoOffsets st1)
             off_i = (off Happy_GHC_Exts.+# nt)
             new_state = indexShortOffAddr happyTable off_i




          in
          happyThen1 (fn stk tk) (\r -> happyNewToken new_state sts1 (r `HappyStk` drop_stk))

happyDrop 0# l = l
happyDrop n (HappyCons (_) (t)) = happyDrop (n Happy_GHC_Exts.-# (1# :: Happy_GHC_Exts.Int#)) t

happyDropStk 0# l = l
happyDropStk n (x `HappyStk` xs) = happyDropStk (n Happy_GHC_Exts.-# (1#::Happy_GHC_Exts.Int#)) xs

-----------------------------------------------------------------------------
-- Moving to a new state after a reduction


happyGoto nt j tk st = 
   {- nothing -}
   happyDoAction j tk new_state
   where off = happyAdjustOffset (indexShortOffAddr happyGotoOffsets st)
         off_i = (off Happy_GHC_Exts.+# nt)
         new_state = indexShortOffAddr happyTable off_i




-----------------------------------------------------------------------------
-- Error recovery (ERROR_TOK is the error token)

-- parse error if we are in recovery and we fail again
happyFail explist 0# tk old_st _ stk@(x `HappyStk` _) =
     let i = (case Happy_GHC_Exts.unsafeCoerce# x of { (Happy_GHC_Exts.I# (i)) -> i }) in
--      trace "failing" $ 
        happyError_ explist i tk

{-  We don't need state discarding for our restricted implementation of
    "error".  In fact, it can cause some bogus parses, so I've disabled it
    for now --SDM

-- discard a state
happyFail  ERROR_TOK tk old_st CONS(HAPPYSTATE(action),sts) 
                                                (saved_tok `HappyStk` _ `HappyStk` stk) =
--      trace ("discarding state, depth " ++ show (length stk))  $
        DO_ACTION(action,ERROR_TOK,tk,sts,(saved_tok`HappyStk`stk))
-}

-- Enter error recovery: generate an error token,
--                       save the old token and carry on.
happyFail explist i tk (action) sts stk =
--      trace "entering error recovery" $
        happyDoAction 0# tk action sts ((Happy_GHC_Exts.unsafeCoerce# (Happy_GHC_Exts.I# (i))) `HappyStk` stk)

-- Internal happy errors:

notHappyAtAll :: a
notHappyAtAll = error "Internal Happy error\n"

-----------------------------------------------------------------------------
-- Hack to get the typechecker to accept our action functions


happyTcHack :: Happy_GHC_Exts.Int# -> a -> a
happyTcHack x y = y
{-# INLINE happyTcHack #-}


-----------------------------------------------------------------------------
-- Seq-ing.  If the --strict flag is given, then Happy emits 
--      happySeq = happyDoSeq
-- otherwise it emits
--      happySeq = happyDontSeq

happyDoSeq, happyDontSeq :: a -> b -> b
happyDoSeq   a b = a `seq` b
happyDontSeq a b = b

-----------------------------------------------------------------------------
-- Don't inline any functions from the template.  GHC has a nasty habit
-- of deciding to inline happyGoto everywhere, which increases the size of
-- the generated parser quite a bit.


{-# NOINLINE happyDoAction #-}
{-# NOINLINE happyTable #-}
{-# NOINLINE happyCheck #-}
{-# NOINLINE happyActOffsets #-}
{-# NOINLINE happyGotoOffsets #-}
{-# NOINLINE happyDefActions #-}

{-# NOINLINE happyShift #-}
{-# NOINLINE happySpecReduce_0 #-}
{-# NOINLINE happySpecReduce_1 #-}
{-# NOINLINE happySpecReduce_2 #-}
{-# NOINLINE happySpecReduce_3 #-}
{-# NOINLINE happyReduce #-}
{-# NOINLINE happyMonadReduce #-}
{-# NOINLINE happyGoto #-}
{-# NOINLINE happyFail #-}

-- end of Happy Template.
