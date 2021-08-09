{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ autoconf, automake, haskell-nix, lib, stdenv, python3 }:
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
      ghc_autogen_files = [
        "_build/stage0/compiler/build/CmmLex.hs"
        "_build/stage0/compiler/build/CmmParse.hs"
        "_build/stage0/compiler/build/Config.hs"
        "_build/stage0/compiler/build/Lexer.hs"
        "_build/stage0/compiler/build/Parser.hs"
        "_build/stage0/compiler/build/primop-can-fail.hs-incl"
        "_build/stage0/compiler/build/primop-code-size.hs-incl"
        "_build/stage0/compiler/build/primop-commutable.hs-incl"
        "_build/stage0/compiler/build/primop-data-decl.hs-incl"
        "_build/stage0/compiler/build/primop-fixity.hs-incl"
        "_build/stage0/compiler/build/primop-has-side-effects.hs-incl"
        "_build/stage0/compiler/build/primop-list.hs-incl"
        "_build/stage0/compiler/build/primop-out-of-line.hs-incl"
        "_build/stage0/compiler/build/primop-primop-info.hs-incl"
        "_build/stage0/compiler/build/primop-strictness.hs-incl"
        "_build/stage0/compiler/build/primop-tag.hs-incl"
        "_build/stage0/compiler/build/primop-vector-tycons.hs-incl"
        "_build/stage0/compiler/build/primop-vector-tys-exports.hs-incl"
        "_build/stage0/compiler/build/primop-vector-tys.hs-incl"
        "_build/stage0/compiler/build/primop-vector-uniques.hs-incl"
        "_build/stage0/lib/DerivedConstants.h"
        "_build/stage0/lib/GHCConstantsHaskellExports.hs"
        "_build/stage0/lib/GHCConstantsHaskellType.hs"
        "_build/stage0/lib/GHCConstantsHaskellWrappers.hs"
        "_build/stage0/lib/ghcautoconf.h"
        "_build/stage0/lib/ghcplatform.h"
        "_build/stage0/lib/ghcversion.h"
        "_build/stage0/libraries/ghc-prim/build/GHC/Prim.hs"
      ];
      ghc_boot_autogen_files = [
        "_build/stage0/libraries/ghc-boot/build/GHC/Platform/Host.hs"
        "_build/stage0/libraries/ghc-boot/build/GHC/Version.hs"
      ];
      ghc_prim_autogen_files = [
        "_build/stage0/libraries/ghc-prim/build/GHC/PrimopWrappers.hs"
      ];
      boot_autogen_files = [
        "_build/stage0/lib/llvm-passes"
        "_build/stage0/lib/llvm-targets"
        "_build/stage0/lib/platformConstants"
        "_build/stage0/lib/settings"
        "_build/stage0/lib/template-hsc.h"
      ];
      rts_autogen_files = [
        "_build/stage0/rts/build/cmm/AutoApply.cmm"
      ];
      ghc-lib-asterius = stdenv.mkDerivation {
        name = "ghc-lib-asterius";
        src = ghc_src;
        outputs = ["out" "boot"];
        nativeBuildInputs = [
          alex
          autoconf
          automake
          haskell-nix.internal-cabal-install
          ghc_boot
          hadrian
          happy
          python3
        ];
        preConfigure = "python3 ./boot --hadrian";
        configureFlags = [ "--disable-tables-next-to-code" ];
        buildPhase = ''
          hadrian -j$NIX_BUILD_CORES --flavour=quickest --integer-simple ${
            lib.concatStringsSep " " (ghc_autogen_files ++ ghc_boot_autogen_files ++ ghc_prim_autogen_files ++ boot_autogen_files ++ rts_autogen_files)
          }
        '';
        installPhase = ''
          export HOME=$(mktemp -d)

          mkdir $out

          cp -r libraries/ghc-heap $TMPDIR/ghc-heap-asterius
          pushd $TMPDIR/ghc-heap-asterius
          patch -p3 -i ${./patches/ghc-heap.patch}
          mv ghc-heap.cabal ghc-heap-asterius.cabal
          cabal v2-sdist
          mkdir $out/ghc-heap-asterius
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ghc-heap-asterius
          popd

          cp -r libraries/ghc-boot-th $TMPDIR/ghc-boot-th-asterius
          pushd $TMPDIR/ghc-boot-th-asterius
          patch -p3 -i ${./patches/ghc-boot-th.patch}
          mv ghc-boot-th.cabal ghc-boot-th-asterius.cabal
          cabal v2-sdist
          mkdir $out/ghc-boot-th-asterius
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ghc-boot-th-asterius
          popd

          cp -r libraries/ghc-boot $TMPDIR/ghc-boot-asterius
          pushd _build/stage0/libraries/ghc-boot/build
          cp --parents GHC/Platform/Host.hs GHC/Version.hs $TMPDIR/ghc-boot-asterius
          popd
          pushd $TMPDIR/ghc-boot-asterius
          patch -p3 -i ${./patches/ghc-boot.patch}
          mv ghc-boot.cabal ghc-boot-asterius.cabal
          cabal v2-sdist
          mkdir $out/ghc-boot-asterius
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ghc-boot-asterius
          popd

          cp -r libraries/template-haskell $TMPDIR/template-haskell-asterius
          pushd $TMPDIR/template-haskell-asterius
          patch -p3 -i ${./patches/template-haskell.patch}
          mv template-haskell.cabal template-haskell-asterius.cabal
          cabal v2-sdist
          mkdir $out/template-haskell-asterius
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/template-haskell-asterius
          popd

          cp -r libraries/ghci $TMPDIR/ghci-asterius
          pushd $TMPDIR/ghci-asterius
          patch -p3 -i ${./patches/ghci.patch}
          mv ghci.cabal ghci-asterius.cabal
          cabal v2-sdist
          mkdir $out/ghci-asterius
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ghci-asterius
          popd

          cp -r compiler $TMPDIR/ghc-asterius
          mkdir $TMPDIR/ghc-asterius/autogen
          cp ${
            lib.concatStringsSep " " ghc_autogen_files
          } $TMPDIR/ghc-asterius/autogen
          cp -r includes/* $TMPDIR/ghc-asterius/autogen
          pushd rts
          cp --parents **/*.h *.h $TMPDIR/ghc-asterius/autogen
          popd
          pushd $TMPDIR/ghc-asterius
          patch -p2 -i ${./patches/ghc.patch}
          mv ghc.cabal ghc-asterius.cabal
          find . -type f -name '*.hs' -exec sed -i 's/#include "\(..\/\)*includes\//#include "/' {} \;
          rm cmm/CmmLex.x cmm/CmmParse.y parser/Lexer.x parser/Parser.y
          cabal v2-sdist
          mkdir $out/ghc-asterius
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ghc-asterius
          popd

          cp -r utils/ghc-pkg $TMPDIR/ahc-pkg
          pushd $TMPDIR/ahc-pkg
          patch -p3 -i ${./patches/ghc-pkg.patch}
          mv ghc-pkg.cabal ahc-pkg.cabal
          cabal v2-sdist
          mkdir $out/ahc-pkg
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ahc-pkg
          popd

          cp -r ghc $TMPDIR/ahc-bin
          cp rts/PosixSource.h $TMPDIR/ahc-bin
          pushd $TMPDIR/ahc-bin
          patch -p2 -i ${./patches/ghc-bin.patch}
          mv ghc-bin.cabal ahc-bin.cabal
          cabal v2-sdist
          mkdir $out/ahc-bin
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $out/ahc-bin
          popd

          mkdir $boot
          cp ${lib.concatStringsSep " " boot_autogen_files} $boot

          mkdir $boot/rts
          cp _build/stage0/rts/build/cmm/AutoApply.cmm rts/*.cmm $boot/rts

          pushd libraries/ghc-prim
          cp ../../_build/stage0/libraries/ghc-prim/build/GHC/PrimopWrappers.hs GHC
          cabal v2-sdist
          mkdir $boot/ghc-prim
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/ghc-prim
          popd

          pushd libraries/integer-simple
          cabal v2-sdist
          mkdir $boot/integer-simple
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/integer-simple
          popd

          pushd libraries/base
          cabal v2-sdist
          mkdir $boot/base
          tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/base
          popd
        '';
        allowedReferences = [ ];
      };
    in
    ghc-lib-asterius)
{ }
