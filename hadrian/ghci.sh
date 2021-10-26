#!/usr/bin/env sh

set -e

GHC_FLAGS="$GHC_FLAGS $(hadrian tool-args -q --build-root=.hadrian_ghci --flavour=ghc-in-ghci "$@")"
ghci $GHC_FLAGS "$@" -fno-code -fwrite-interface -hidir=.hadrian_ghci/interface -O0 ghc/Main.hs +RTS -A128m
