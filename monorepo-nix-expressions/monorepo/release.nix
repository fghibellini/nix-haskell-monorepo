let

  nixpkgs = import (import ./pinned-nixpkgs.nix) { inherit config; };

  monorepo-pkgs = import ./packages.nix;

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskell.packages.ghc844.override {
        overrides = self: super: builtins.mapAttrs (name: value: super.callPackage value {}) monorepo-pkgs;
      };
    };
  };

in nixpkgs
