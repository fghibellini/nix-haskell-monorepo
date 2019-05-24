let

  nixpkgs = import (import ./pinned-nixpkgs.nix) { inherit config; };

  gitignore = nixpkgs.nix-gitignore.gitignoreSourcePure [ ../.gitignore ];
  extra-deps = import ./extra-deps.nix;

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskell.packages.ghc864.override {
        overrides = self: super: ((extra-deps super) // builtins.mapAttrs (name: path: super.callCabal2nix name (gitignore path) {}) (import ./packages.nix));
      };
    };
  };

in nixpkgs
