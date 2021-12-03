{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import haskellNix.sources.nixpkgs-unstable haskellNix.nixpkgsArgs
}:
pkgs.pkgsCross.gnu32.callPackage
  ({ autoconf, automake, git, gnum4, python3, stdenv, util-linux }:
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
        src = pkgs.haskell-nix.haskellLib.cleanGit {
          name = "hadrian_src";
          src = ../.;
          subDir = "hadrian";
        };
        compiler-nix-name = ghc_boot_ver;
        modules = (import ./modules.nix) ++ [{ reinstallableLibGhc = true; }];
      }).hadrian.components.exes.hadrian;
      alex = pkgs.haskell-nix.hackage-tool {
        name = "alex";
        version = "3.2.6";
        compiler-nix-name = ghc_boot_ver;
        modules = import ./modules.nix;
      };
      happy = pkgs.haskell-nix.hackage-tool {
        name = "happy";
        version = "1.19.12";
        compiler-nix-name = ghc_boot_ver;
        modules = import ./modules.nix;
      };
    in
    stdenv.mkDerivation {
      name = "ghc-lib-asterius";
      dontUnpack = true;
      postPatch = "patchShebangs .";
      nativeBuildInputs = [
        alex
        autoconf
        automake
        ghc_boot
        git
        gnum4
        hadrian
        happy
        python3
        util-linux
      ];
      installPhase = "export > $out";
      shellHook = "taskset -pc 0-1000 $$";
    })
{ }
