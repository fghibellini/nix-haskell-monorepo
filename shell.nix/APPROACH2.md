
# ATTEMPT #3 - `<package>.getBuildInputs.haskellBuildInputs`

This does work and is much simplier than the argument-name-extraction method, but
for some reason the result takes much longer to build.
I haven't had the time to investigate why.

```nix
let
  nixpkgs = import ./release.nix;
  monorepo-packages = builtins.attrValues (import ./hydra.nix);
  is-monorepo-pkg = x: builtins.any (p: p.pname == x.pname) monorepo-packages;
  all-deps = builtins.concatMap (pkg: pkg.getBuildInputs.haskellBuildInputs) monorepo-packages;
  external-deps = builtins.filter (x: ! is-monorepo-pkg x) all-deps;
in
  nixpkgs.haskellPackages.mkDerivation {
    pname = "monorepo";
    version = "1.0.0";
    src = null;
    libraryHaskellDepends = external-deps;
    license = nixpkgs.stdenv.lib.licenses.unfree;
  }
```
