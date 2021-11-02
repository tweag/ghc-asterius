{-# LANGUAGE CPP #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-orphans #-}

#if defined(ASTERIUS)
module Asterius.Types.JSString
  ( JSString (..),
    lengthOfJSString,
    fromJSString,
    toJSString,
  )
where

import Asterius.Magic
import Asterius.Types.JSVal
import Data.Functor
import Data.String
import GHC.Base
import GHC.Enum
import GHC.Read
import GHC.Show

newtype JSString = JSString JSVal
  deriving (Eq, Ord)

{-# INLINEABLE fromJSString #-}
fromJSString :: JSString -> String
fromJSString s = accursedUnutterablePerformIO $ do
  it <- js_fromJSString_iterator s
  let w = do
        c <- js_fromJSString_iterator_next it
        case c of
          '\0' -> do
            freeJSVal it
            pure []
          _ -> pure (pred c : accursedUnutterablePerformIO w)
   in w

instance Show JSString where
  {-# INLINE showsPrec #-}
  showsPrec p = showsPrec p . fromJSString

instance Show JSVal where
  {-# INLINE show #-}
  show = fromJSString . js_showJSVal

{-# INLINEABLE toJSString #-}
toJSString :: String -> JSString
toJSString s = accursedUnutterablePerformIO $ do
  ctx <- js_toJSString_context_new
  let w (c : cs) = js_toJSString_context_push ctx c *> w cs
      w [] = pure ()
   in w s
  r <- js_toJSString_context_result ctx
  freeJSVal ctx
  pure r

instance IsString JSString where
  {-# INLINE fromString #-}
  fromString = toJSString

instance Read JSString where
  {-# INLINE readPrec #-}
  readPrec = fmap toJSString readPrec

foreign import javascript unsafe "$1.length"
  lengthOfJSString :: JSString -> Int

foreign import javascript unsafe "`${$1}`" js_showJSVal :: JSVal -> JSString

foreign import javascript unsafe "$1[Symbol.iterator]()" js_fromJSString_iterator :: JSString -> IO JSVal

foreign import javascript unsafe "(() => { const r = $1.next(); return r.done ? 0 : (1 + r.value.codePointAt(0)); })()" js_fromJSString_iterator_next :: JSVal -> IO Char

foreign import javascript unsafe "['']" js_toJSString_context_new :: IO JSVal

foreign import javascript unsafe "$1[0] += String.fromCodePoint($2)" js_toJSString_context_push :: JSVal -> Char -> IO ()

foreign import javascript unsafe "$1[0]" js_toJSString_context_result :: JSVal -> IO JSString
#else
module Asterius.Types.JSString where
#endif
