[
  { configureFlags = [ "-O2" ]; }
  { dontPatchELF = false; }
  { dontStrip = false; }
  { hardeningDisable = [ "all" ]; }
]
