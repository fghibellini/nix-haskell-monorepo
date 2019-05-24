let
    nixpkgs = import ./release.nix;
    packages = import ./packages.nix;

    mapAttrs = nixpkgs.lib.mapAttrs;

in
    mapAttrs (name: path: builtins.getAttr name nixpkgs.haskellPackages) packages
