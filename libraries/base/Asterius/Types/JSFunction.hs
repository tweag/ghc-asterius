{-# LANGUAGE CPP #-}
{-# LANGUAGE NoImplicitPrelude #-}

#if defined(ASTERIUS)
module Asterius.Types.JSFunction
  ( JSFunction (..),
    freeHaskellCallback,
  )
where

import Asterius.Types.JSString ()
import Asterius.Types.JSVal
import GHC.Base
import GHC.Show

newtype JSFunction
  = JSFunction JSVal
  deriving (Show)

foreign import ccall unsafe "freeHaskellCallback"
  freeHaskellCallback :: JSFunction -> IO ()
#else
module Asterius.Types.JSFunction where
#endif
