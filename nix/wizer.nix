{ autoPatchelfHook, fetchzip, lib, stdenv }:
stdenv.mkDerivation rec {
  name = "wizer";
  version = "1.3.4";
  src = fetchzip {
    x86_64-linux = {
      url =
        "https://github.com/bytecodealliance/wizer/releases/download/dev/wizer-dev-x86_64-linux.tar.xz";
      hash =
        "sha512-325/FchWIj3WUTE8RumT2NE77LHYQiA+pOgBTQh7HDXaMVwx7cMcFsKENrNzsFvDSdSd1haoJBDm7K5IN3PGJA==";
    };
    x86_64-darwin = {
      url =
        "https://github.com/bytecodealliance/wizer/releases/download/dev/wizer-dev-x86_64-macos.tar.xz";
      hash =
        "sha512-ET/bA6UxEztoLpYCPX3cB8cBDJveJPnZlVnSAOc9H4eVWhiqqdVqm/KIGZAjPdmeFoB4q9uBdX3V1eY4xFj0sg==";
    };
  }.${stdenv.hostPlatform.system};
  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    mv wizer $out/bin
  '';
  doInstallCheck = true;
  installCheckPhase = "$out/bin/wizer --version";
}
