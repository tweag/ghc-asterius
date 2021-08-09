{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.pkgsi686Linux.callPackage
  ({ autoconf
   , automake
   , git
   , gmp
   , haskell-nix
   , lib
   , llvmPackages_13
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
    stdenv.mkDerivation {
      name = "ghc-asterius-validate-32";
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
        llvmPackages_13.llvm
        perl
        python3
        util-linux
        which
      ];
      preConfigure = "./boot --hadrian";
      configureFlags = [
        "--enable-unregisterised"
        "--with-curses-includes=${ncurses.dev}/include"
        "--with-curses-libraries=${ncurses.out}/lib"
        "--with-gmp-includes=${gmp.dev}/include"
        "--with-gmp-libraries=${gmp.out}/lib"
      ];
      buildPhase = ''
        mkdir -p $out
        (hadrian \
          --flavour=slow-validate \
          -j$NIX_BUILD_CORES \
          -V \
          test \
          --test-way=normal \
          --test-way=g1 \
          --test-way=nursery_chunks \
          --test-way=optasm \
          --test-way=llvm \
          --test-way=optllvm \
          --test-way=sanity \
          --test-way=dyn \
          --test-way=static \
          --test-way=debug \
          --test-way=ext-interp \
          --test-way=nonmoving \
          --summary=$out/summary.txt 2>&1 || true) | tee $out/report.txt
      '';
      dontInstall = true;
      shellHook = ''
        taskset -pc 0-1000 $$

        export out=$(mktemp -d)
        export dontUnpack=true
      '';
    })
{ }
