{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import haskellNix.sources.nixpkgs-unstable haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ haskell-nix, lib, runCommand, stdenv }:
    let
      src = import ./src-32.nix { };
      cabalProject = ''
        packages:
          ahc-bin
          ahc-pkg
          ghc-boot-asterius
          ghc-boot-th-asterius
          ghc-heap-asterius
          ghc-asterius
          ghci-asterius
          template-haskell-asterius
      '';
      check-cabal = compiler-nix-name:
        stdenv.mkDerivation {
          name = "check-cabal-${compiler-nix-name}";
          inherit src;
          nativeBuildInputs = [
            haskell-nix.internal-cabal-install
            haskell-nix.compiler."${compiler-nix-name}"
          ];
          buildPhase = ''
            printf '#include "Cmm.h"\n' > test.c
            $CC -Ighc-asterius/autogen -fsyntax-only test.c
            printf '#include "Rts.h"\n#include "Capability.h"\n#include "Schedule.h"\n' > test.c
            $CC -Ighc-asterius/autogen -fsyntax-only test.c

            export HOME=$(mktemp -d)
            mkdir $HOME/.cabal
            echo "offline: True" > $HOME/.cabal/config

            printf ${lib.escapeShellArg cabalProject} > cabal.project
            cabal v2-build -O0 -j$NIX_BUILD_CORES --ghc-option=-j$(($NIX_BUILD_CORES > 4 ? 4 : $NIX_BUILD_CORES)) all
          '';
          installPhase = "export > $out";
        };
      check-all = runCommand "check-all"
        {
          paths = lib.concatMap (v: [ (check-cabal v) ]) [ "ghc8107" ];
        } "export > $out";
    in
    check-all)
{ }
