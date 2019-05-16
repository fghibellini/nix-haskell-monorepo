let

  nixpkgs = import (import ./pinned-nixpkgs.nix) { inherit config; };

  monorepo-pkgs = import ./packages.nix;
  extra-deps = import ./extra-deps.nix;

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskell.packages.ghc844.override {
        overrides = self: super: (extra-deps super) // (builtins.mapAttrs (name: value: super.callPackage value {}) monorepo-pkgs);
      };
    };
  };

in nixpkgs
