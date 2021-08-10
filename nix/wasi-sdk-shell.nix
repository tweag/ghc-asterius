{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ autoconf
   , automake
   , binaryen
   , git
   , haskell-nix
   , lib
   , libtool
   , python3
   , stdenv
   , stdenvNoCC
   , util-linux
   , wabt
   }:
    let
      ghc_boot_ver = "ghc8107";
      ghc_boot = haskell-nix.compiler."${ghc_boot_ver}".overrideAttrs
        (ghc_attrs: {
          src = ghc_attrs.src.overrideAttrs (ghc_src_attrs: {
            configureFlags = ghc_src_attrs.configureFlags ++ [ "--disable-numa" ];
          });
          propagatedBuildInputs = [ ];
        });
      hadrian = (haskell-nix.cabalProject {
        src = haskell-nix.haskellLib.cleanGit {
          name = "hadrian_src";
          src = ../.;
          subDir = "hadrian";
        };
        compiler-nix-name = ghc_boot_ver;
        modules = (import ./modules.nix) ++ [{ reinstallableLibGhc = true; }];
      }).hadrian.components.exes.hadrian;
      alex = haskell-nix.hackage-tool {
        name = "alex";
        version = "3.2.6";
        compiler-nix-name = ghc_boot_ver;
        modules = import ./modules.nix;
      };
      happy = haskell-nix.hackage-tool {
        name = "happy";
        version = "1.19.12";
        compiler-nix-name = ghc_boot_ver;
        modules = import ./modules.nix;
      };
    in
    stdenvNoCC.mkDerivation ({
      name = "ghc-asterius-wasi-sdk-shell";
      dontUnpack = true;
      nativeBuildInputs = [
        alex
        autoconf
        automake
        binaryen
        ghc_boot
        git
        hadrian
        happy
        libtool
        python3
        util-linux
        wabt
        (pkgs.callPackage "${sources.wasi-sdk}/nix/wasmtime.nix" { })
        (pkgs.callPackage ./wizer.nix { })
      ];
      installPhase = "export > $out";
      shellHook = "taskset -pc 0-1000 $$";
    } // (import ./wasi-sdk-stdenv.nix {
      inherit stdenv;
      wasi-sdk = import "${sources.wasi-sdk}/nix/default.nix" { };
    })))
{ }
