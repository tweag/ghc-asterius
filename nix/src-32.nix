{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ autoconf, automake, haskell-nix, lib, stdenv, stdenvNoCC, python3 }:
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
      wasi-sdk = import "${sources.wasi-sdk}/nix/default.nix" { };
      ghc_stage0_autogen_files = [
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
      ];
      ghc_boot_stage0_autogen_files = [
        "_build/stage0/libraries/ghc-boot/build/GHC/Platform/Host.hs"
        "_build/stage0/libraries/ghc-boot/build/GHC/Version.hs"
      ];
      ghc_boot_stage1_autogen_files = [
        "_build/stage1/libraries/ghc-boot/build/GHC/Platform/Host.hs"
        "_build/stage1/libraries/ghc-boot/build/GHC/Version.hs"
      ];
      ghc_prim_stage1_autogen_files =
        [ "_build/stage1/libraries/ghc-prim/build/GHC/PrimopWrappers.hs" ];
      libdir_stage0_autogen_files = [
        "_build/stage0/lib/llvm-passes"
        "_build/stage0/lib/llvm-targets"
        "_build/stage0/lib/platformConstants"
        "_build/stage0/lib/settings"
        "_build/stage0/lib/template-hsc.h"
      ];
      libdir_stage1_autogen_files = [
        "_build/stage1/lib/llvm-passes"
        "_build/stage1/lib/llvm-targets"
        "_build/stage1/lib/platformConstants"
        "_build/stage1/lib/settings"
        "_build/stage1/lib/template-hsc.h"
      ];
      rts_stage1_autogen_files = [ "_build/stage1/rts/build/cmm/AutoApply.cmm" ];
    in
    stdenvNoCC.mkDerivation ({
      name = "ghc-lib-asterius";
      src = ghc_src;
      outputs = [ "out" "boot" ];
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
      preConfigure = ''
        python3 ./boot --hadrian
        configureFlagsArray+=(
          "--target=wasm32-unknown-wasi"
          "--enable-unregisterised"
          "--with-hs-cpp=$CC"
          "--with-hs-cpp-flags=-E -undef -traditional"
          "CONF_CC_OPTS_STAGE2=-DASTERIUS"
          "CONF_CXX_OPTS_STAGE2=-DASTERIUS"
        )
      '';
      buildPhase = ''
        hadrian -j$NIX_BUILD_CORES --flavour=quickest --integer-simple -V ${
          lib.concatStringsSep " " (ghc_stage0_autogen_files
            ++ ghc_boot_stage0_autogen_files ++ ghc_boot_stage1_autogen_files
            ++ ghc_prim_stage1_autogen_files ++ libdir_stage0_autogen_files
            ++ libdir_stage1_autogen_files ++ rts_stage1_autogen_files)
        }
        substituteInPlace _build/stage0/lib/settings \
          --replace '-E -undef -traditional' '-E -undef -traditional -DASTERIUS'
        substituteInPlace _build/stage1/lib/settings \
          --replace '-E -undef -traditional' '-E -undef -traditional -DASTERIUS'

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
        cp -r includes/* $TMPDIR/ghc-asterius/autogen
        pushd rts
        cp --parents **/*.h *.h $TMPDIR/ghc-asterius/autogen
        popd
        cp ${
          lib.concatStringsSep " " ghc_stage0_autogen_files
        } $TMPDIR/ghc-asterius/autogen
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
        cp ${lib.concatStringsSep " " libdir_stage1_autogen_files} $boot

        mkdir $boot/rts
        cp _build/stage1/rts/build/cmm/AutoApply.cmm rts/*.cmm $boot/rts

        pushd libraries/ghc-prim
        cp ../../_build/stage1/libraries/ghc-prim/build/GHC/PrimopWrappers.hs GHC
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

        pushd libraries/ghc-heap
        cabal v2-sdist
        mkdir $boot/ghc-heap
        tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/ghc-heap
        popd

        pushd libraries/ghc-boot-th
        cabal v2-sdist
        mkdir $boot/ghc-boot-th
        tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/ghc-boot-th
        popd

        pushd _build/stage1/libraries/ghc-boot/build
        cp --parents GHC/Platform/Host.hs GHC/Version.hs ../../../../../libraries/ghc-boot
        popd
        pushd libraries/ghc-boot
        cabal v2-sdist
        mkdir $boot/ghc-boot
        tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/ghc-boot
        popd

        pushd libraries/template-haskell
        cabal v2-sdist
        mkdir $boot/template-haskell
        tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/template-haskell
        popd

        pushd libraries/ghci
        cabal v2-sdist
        mkdir $boot/ghci
        tar xf dist-newstyle/sdist/*.tar.gz --strip-components=1 -C $boot/ghci
        popd
      '';
      dontInstall = true;
      allowedReferences = [ wasi-sdk ];
    } // (import ./wasi-sdk-stdenv.nix { inherit stdenv wasi-sdk; })))
{ }
