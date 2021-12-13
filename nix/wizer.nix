{ fetchFromGitHub, fetchpatch, rustPlatform }:
rustPlatform.buildRustPackage rec {
  pname = "wizer";
  version = "1.3.4";
  src = fetchFromGitHub {
    owner = "bytecodealliance";
    repo = pname;
    rev = "e50deb56c833919e9a9cffdea0e8305367d80d8e";
    sha256 = "sha256-6Q08AzHTuYKdnsGdsvKKvWG+shDdojXY29Hitjn6I0Y=";
    fetchSubmodules = true;
  };
  patches = [
    (fetchpatch {
      url =
        "https://patch-diff.githubusercontent.com/raw/bytecodealliance/wizer/pull/37.diff";
      sha256 = "sha256-qRAxDSS9+tSHP5YlAOC+aWwQoobyjXkWhWHuL8mWlWs=";
    })
  ];
  cargoHash =
    "sha512-FZgHo0PDJnHr0RB/aJ1iMovmekUUpWf7S30W+a7cxSXxQGETgBJ5Gto0RvbZucwYmJ3QGljtxXJli+O2KystEw==";
  cargoBuildFlags = [ "--bin=wizer" "--features=env_logger,structopt" ];
  preCheck = "export HOME=$(mktemp -d)";
}
