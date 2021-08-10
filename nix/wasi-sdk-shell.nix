{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.pkgsCross.wasi32.callPackage
  ({ autoconf
   , automake
   , buildPackages
   , git
   , haskell-nix
   , lib
   , stdenvNoCC
   , python3
   , util-linux
   }:
    let
      ghc_boot_ver = "ghc8107";
      ghc_boot = pkgs.haskell-nix.compiler."${ghc_boot_ver}".overrideAttrs
        (ghc_attrs: {
          src = ghc_attrs.src.overrideAttrs (ghc_src_attrs: {
            configureFlags = ghc_src_attrs.configureFlags ++ [ "--disable-numa" ];
          });
          propagatedBuildInputs = [ ];
        });
      hadrian = (pkgs.haskell-nix.cabalProject {
        src = haskell-nix.haskellLib.cleanGit {
          name = "hadrian_src";
          src = ../.;
          subDir = "hadrian";
        };
        compiler-nix-name = ghc_boot_ver;
        modules = [
          { dontPatchELF = false; }
          { dontStrip = false; }
          { hardeningDisable = [ "all" ]; }
          { reinstallableLibGhc = true; }
          {
            packages.hadrian.postUnpack =
              "cp ${./UserSettings.hs} $sourceRoot/UserSettings.hs";
          }
        ];
      }).hadrian.components.exes.hadrian;
      alex = pkgs.haskell-nix.hackage-tool {
        name = "alex";
        version = "3.2.6";
        compiler-nix-name = ghc_boot_ver;
        modules = [
          { dontPatchELF = false; }
          { dontStrip = false; }
          { hardeningDisable = [ "all" ]; }
        ];
      };
      happy = pkgs.haskell-nix.hackage-tool {
        name = "happy";
        version = "1.19.12";
        compiler-nix-name = ghc_boot_ver;
        modules = [
          { dontPatchELF = false; }
          { dontStrip = false; }
          { hardeningDisable = [ "all" ]; }
        ];
      };
    in
    stdenvNoCC.mkDerivation ({
      name = "ghc-asterius-wasi-sdk-shell";
      dontUnpack = true;
      nativeBuildInputs =
        [ alex autoconf automake ghc_boot git hadrian happy python3 util-linux ];
      installPhase = "export > $out";
      shellHook = "taskset -pc 0-1000 $$";
    } // (import ./wasi-sdk-stdenv.nix {
      stdenv = buildPackages.stdenv;
      wasi-sdk = import "${sources.wasi-sdk}/nix/default.nix" { };
    })))
{ }
