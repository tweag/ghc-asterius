{ sources ? import ./sources.nix { }
, haskellNix ? import sources.haskell-nix { }
, pkgs ? import sources.nixpkgs haskellNix.nixpkgsArgs
}:
pkgs.callPackage
  ({ git, haskell-nix, lib, util-linux }:
    let
      src = import ./src.nix { inherit pkgs; };
      tools = lib.attrValues (import sources.hs-nix-tools { ghc = "ghc8107"; });
    in
    src.overrideAttrs (super: {
      nativeBuildInputs = tools ++ [ git util-linux ] ++ super.nativeBuildInputs;
      phases = [ "installPhase" ];
      installPhase = "export > $out";
      allowedReferences = null;
      shellHook = "taskset -pc 0-1000 $$";
    }))
{ }
