{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ autoconf, automake, haskell-nix, lib, python3, stdenv, stdenvNoCC }:
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
      libdir_stage1_autogen_files =
        [ "_build/stage1/lib/ghcautoconf.h" "_build/stage1/lib/ghcplatform.h" ];
    in
    stdenvNoCC.mkDerivation ({
      name = "ghc-asterius-wasi-rts";
      src = ghc_src;
      nativeBuildInputs =
        [ alex autoconf automake ghc_boot hadrian happy python3 ];
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
        hadrian -j$NIX_BUILD_CORES -V ${
          lib.concatStringsSep " " libdir_stage1_autogen_files
        }
        mkdir -p $out/bin
        $CC \
          -Wall \
          -Wextra \
          -Oz \
          -flto \
          -mexec-model=reactor \
          -DHAVE_SIGNAL_H \
          -DHAVE_SYS_MMAN_H \
          -D_WASI_EMULATED_MMAN \
          -D_WASI_EMULATED_SIGNAL \
          -Dsiginfo_t=char \
          -DNO_REGS \
          -DUSE_MINIINTERPRETER \
          -DProjectVersion=\"8.10.7\" \
          -DHostPlatform=\"x86_64-unknown-linux\" \
          -DHostArch=\"x86_64\" \
          -DHostOS=\"linux\" \
          -DHostVendor=\"unknown\" \
          -DBuildPlatform=\"x86_64-unknown-linux\" \
          -DBuildArch=\"x86_64\" \
          -DBuildOS=\"linux\" \
          -DBuildVendor=\"unknown\" \
          -DTargetPlatform=\"wasm32-unknown-wasi\" \
          -DTargetArch=\"wasm32\" \
          -DTargetOS=\"wasi\" \
          -DTargetVendor=\"unknown\" \
          -DGhcUnregisterised=\"YES\" \
          -DTablesNextToCode=\"NO\" \
          -DRtsWay=\"v\" \
          -I_build/stage1/lib \
          -Iincludes \
          -Ilibraries/base/include \
          -Inix/rts \
          -Irts \
          -Wl,--compress-relocations \
          -Wl,--export-table \
          -Wl,--export=__hsbase_MD5Final \
          -Wl,--export=__hsbase_MD5Init \
          -Wl,--export=__hsbase_MD5Transform \
          -Wl,--export=__hsbase_MD5Update \
          -Wl,--export=aligned_alloc \
          -Wl,--export=allocGroup_lock \
          -Wl,--export=allocate \
          -Wl,--export=allocatePinned \
          -Wl,--export=free \
          -Wl,--export=getMBlocks \
          -Wl,--export=memcpy \
          -Wl,--export=freeGroup_lock \
          -Wl,--export=rts_unsafeGetMyCapability \
          -Wl,--growable-table \
          -Wl,--lto-O3 \
          -Wl,--stack-first \
          -Wl,--strip-all \
          libraries/base/cbits/md5.c \
          nix/rts/rts.c \
          rts/posix/OSMem.c \
          rts/sm/BlockAlloc.c \
          rts/sm/MBlock.c \
          rts/sm/GC.c \
          rts/sm/NonMoving.c \
          rts/sm/NonMovingMark.c \
          rts/sm/Storage.c \
          rts/Capability.c \
          rts/RtsFlags.c \
          rts/RtsMessages.c \
          rts/RtsUtils.c \
          rts/WSDeque.c \
          -o $out/bin/rts.wasm
      '';
      dontInstall = true;
      allowedReferences = [ ];
    } // (import ./wasi-sdk-stdenv.nix {
      inherit stdenv;
      wasi-sdk = import "${sources.wasi-sdk}/nix/default.nix" { };
    })))
{ }
