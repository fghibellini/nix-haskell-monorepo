let
  nixpkgs = import ./release.nix;
  all-deps = (nixpkgs.callPackage ./lib/compute-monorepo-deps.nix {}) ./packages;
in
  nixpkgs.haskellPackages.mkDerivation {
    pname = "monorepo";
    version = "1.0.0";
    src = null;
    libraryHaskellDepends = map (pkgName: builtins.getAttr pkgName nixpkgs.haskellPackages) all-deps;
    license = nixpkgs.stdenv.lib.licenses.unfree;
  }
