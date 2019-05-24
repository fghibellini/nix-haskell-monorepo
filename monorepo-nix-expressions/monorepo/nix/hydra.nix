let

    nixpkgs = import ./release.nix;
    monorepo-pkgs = import ./monorepo.nix;

    doHaddock = nixpkgs.haskell.lib.doHaddock;
    doCoverage = nixpkgs.haskell.lib.doCoverage;
    mapAttrs = nixpkgs.lib.mapAttrs;

in

    mapAttrs (name: value: doHaddock (doCoverage value)) monorepo-pkgs
