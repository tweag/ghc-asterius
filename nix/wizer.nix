{ fetchFromGitHub, fetchpatch, lib, rustPlatform }:
rustPlatform.buildRustPackage rec {
  pname = "wizer";
  version = "1.3.4";
  src = fetchFromGitHub {
    owner = "bytecodealliance";
    repo = pname;
    rev = "90a4f9edb3a145ec950f348730e6fd4ec2e31ed3";
    sha256 = "sha256-0XTaF1k7O+MBpxPc0JVhEYw6VSkZ1NNP+re1Ttpwr1k=";
    fetchSubmodules = true;
  };
  patches = [
    (fetchpatch {
      url =
        "https://patch-diff.githubusercontent.com/raw/bytecodealliance/wizer/pull/36.diff";
      sha256 = "sha256-+llP5xHk3fuZ8vTPciRBiIc2vBmXBnGtK1CF6GoID6E=";
    })
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
