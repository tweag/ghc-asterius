{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ autoconf
   , automake
   , git
   , gmp
   , haskell-nix
   , lib
   , ncurses
   , perl
   , python3
   , stdenv
   , util-linux
   , which
   }:
    let
      ghc_src = haskell-nix.haskellLib.cleanGit {
        name = "ghc_src";
        src = ../.;
      };
      ghc_boot_ver = "ghc8107";
      ghc_boot = haskell-nix.compiler."${ghc_boot_ver}";
      hadrian = (haskell-nix.cabalProject {
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
        ];
      }).hadrian.components.exes.hadrian;
      alex = haskell-nix.hackage-tool {
        name = "alex";
        version = "3.2.6";
        compiler-nix-name = ghc_boot_ver;
        modules = [
          { dontPatchELF = false; }
          { dontStrip = false; }
          { hardeningDisable = [ "all" ]; }
        ];
      };
      happy = haskell-nix.hackage-tool {
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
    stdenv.mkDerivation {
      name = "ghc-asterius-validate";
      src = ghc_src;
      postPatch = "patchShebangs .";
      nativeBuildInputs = [
        alex
        autoconf
        automake
        ghc_boot
        git
        hadrian
        happy
        perl
        python3
        util-linux
        which
      ];
      preConfigure = "./boot --hadrian";
      configureFlags = [
        "--with-curses-includes=${ncurses.dev}/include"
        "--with-curses-libraries=${ncurses.out}/lib"
        "--with-gmp-includes=${gmp.dev}/include"
        "--with-gmp-libraries=${gmp.out}/lib"
      ];
      buildPhase =
        "(hadrian --flavour=validate -j$NIX_BUILD_CORES test 2>&1 || true) | tee $out";
      dontInstall = true;
      shellHook = "taskset -pc 0-1000 $$";
    })
{ }
