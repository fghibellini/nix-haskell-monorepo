
# Monorepo Nix Expressions

Now it's time to put our haskell code to work.
Each of our haskell packages has to have a corresponding nix expression describing how to build it.
Since we can assume the set of haskell packages and their dependencies will be chaning quite often, we better
generate those nix files.

To achieve this I use a very simple bash script that expects a directory as an argument.
It will first search for all the cabal files in the directory and it will generate one nix expression file for each of them using the `cabal2nix` utility.

```
$ nix-env -iA nixpkgs.cabal2nix # used by generate-packages.sh

$ cd monorepo

$ tree .
.
└── code
    ├── package1
    │   ├── package1.cabal
    │   └── exe
    └── package2
        ├── package2.cabal
        └── src

$ ../generate-packages.sh ../code

$ tree .
.
├── code
│   ├── package1
│   │   ├── package1.cabal
│   │   └── exe
│   └── package2
│       ├── package2.cabal
│       └── src
├── hydra.nix
├── packages
│   ├── package1.nix
│   └── package2.nix
└── packages.nix

$ cat packages/package1.nix
{ mkDerivation, aeson, base, package2, stdenv, text }:
mkDerivation {
  pname = "package1";
  version = "0.1.0.0";
  src = .././code/package1;
  libraryHaskellDepends = [ aeson base package2 text ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}

$ cat packages.nix
{
    package2 = import ./packages/package2.nix;
    package1 = import ./packages/package1.nix;
}
```

As you can see it also generated a `packages.nix` file that just imports all of the above files and bundles them in an attribute set for easier consumption.
This file is not strictly necessary as Nix allows you to scan directories for files but I find it makes the expressions more readable.

Assuming our packages really do depend only on each other or their dependencies can be satisfied with packages from our pinned nixpkgs, we can already take them for a spin.
We will build our packages by inserting them into the haskell package set of nixpkgs.
Nixpkgs accepts a config argument that allows us to override packages in a function (non-destructive) manner.
We override `haskellPackages` to be the package set for `ghc844` but before assigning it we also modify the set by adding our own packages.

```nix
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
```

Then we can build and execute our package by running:

```bash
$ nix-build -A haskellPackages.package1 ./release.nix
$ ./result/bin/package1-exe
Hello lollipop!
```

Or in an ephemeral shell environment:

```bash
$ nix-shell -p "(import ./release.nix).haskellPackages.package1" --run "package1-exe"
Hello lollipop!
```

Or use it as a dependency:

```bash
$ nix-shell -p "(import ./release.nix).haskellPackages.ghcWithPackages (pkgs: [ pkgs.package1 ])"
```
