{-# LANGUAGE MagicHash #-}
{-# LANGUAGE UnliftedFFITypes #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Asterius.Types.JSVal
  ( JSVal (..),
    freeJSVal,
  )
where

import GHC.Base
import GHC.Exts

type JSVal# = StableName# ()

data JSVal
  = JSVal JSVal#

instance Eq JSVal where
  {-# INLINE (==) #-}
  (==) = js_eqJSVal

instance Ord JSVal where
  {-# INLINE (<=) #-}
  (<=) = js_leJSVal

{-# INLINE freeJSVal #-}
freeJSVal :: JSVal -> IO ()
freeJSVal (JSVal sn) = js_freeJSVal sn

foreign import javascript unsafe "__asterius_jsffi.freeJSValzh($1)" js_freeJSVal :: JSVal# -> IO ()

foreign import javascript unsafe "$1 === $2" js_eqJSVal :: JSVal -> JSVal -> Bool

foreign import javascript unsafe "$1 <= $2" js_leJSVal :: JSVal -> JSVal -> Bool
