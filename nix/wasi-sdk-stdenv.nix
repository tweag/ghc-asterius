{ stdenv, wasi-sdk }: {
  AR = "${wasi-sdk}/bin/llvm-ar";
  CC = "${wasi-sdk}/bin/clang";
  CC_FOR_BUILD = "${stdenv.cc}/bin/cc";
  CXX = "${wasi-sdk}/bin/clang++";
  LD = "${wasi-sdk}/bin/wasm-ld";
  NM = "${wasi-sdk}/bin/llvm-nm";
  OBJCOPY = "${wasi-sdk}/bin/llvm-objcopy";
  OBJDUMP = "${wasi-sdk}/bin/llvm-objdump";
  RANLIB = "${wasi-sdk}/bin/llvm-ranlib";
  SIZE = "${wasi-sdk}/bin/llvm-size";
  STRIP = "${wasi-sdk}/bin/llvm-strip";
}
