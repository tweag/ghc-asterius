{-# LANGUAGE CPP #-}

module GHC.Platform.X86_64 where

import GhcPrelude

#define MACHREGS_NO_REGS 0
#define MACHREGS_x86_64 1
#include "CodeGen.Platform.hs"

