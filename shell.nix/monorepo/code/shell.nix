let

    nixpkgs = import ../nix/release.nix;
    monorepo-pkgs = import ../nix/monorepo.nix;

in

    nixpkgs.haskellPackages.shellFor {
        packages = p: builtins.attrValues monorepo-pkgs;
        buildInputs = [
            nixpkgs.haskellPackages.cabal-install
        ];
    }
