
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
├── code
│   ├── package1
│   │   ├── package1.cabal
│   │   └── src
│   │       └── Main.hs
│   └── package2
│       ├── exe
│       │   └── Lollipops
│       │       └── Colorant.hs
│       └── package2.cabal
└── nix
    ├── generate-packages.sh
    ├── pinned-nixpkgs.nix
    └── release.nix

$ cd nix
$ ./generate-packages.sh ../code

$ cd ..
$ tree .
.
├── code
│   ├── package1
│   │   ├── package1.cabal
│   │   └── src
│   │       └── Main.hs
│   └── package2
│       ├── exe
│       │   └── Lollipops
│       │       └── Colorant.hs
│       └── package2.cabal
└── nix
    ├── generate-packages.sh
    ├── hydra.nix
    ├── packages
    │   ├── package1.nix
    │   └── package2.nix
    ├── packages.nix
    ├── pinned-nixpkgs.nix
    └── release.nix

$ cat nix/packages/package1.nix
{ mkDerivation, aeson, base, package2, stdenv, text }:
mkDerivation {
  pname = "package1";
  version = "0.1.0.0";
  src = .././code/package1;
  libraryHaskellDepends = [ aeson base package2 text ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}

$ cat nix/packages.nix
{
    package2 = import ./packages/package2.nix;
    package1 = import ./packages/package1.nix;
}
```

As you can see it also generated a `packages.nix` file that just imports all of the above files and bundles them in an attribute set for easier consumption.
This file is not strictly necessary as Nix allows you to scan directories for files but I find it makes the expressions more readable.

Assuming our packages really do depend only on each other or their dependencies can be satisfied with packages from our pinned nixpkgs, we can already take them for a spin.
We will build our packages by inserting them into the haskell package set of nixpkgs.
Nixpkgs accepts a config argument that allows us to override packages in a functional (non-destructive) manner.
We override `haskellPackages` to be the package set for `ghc844` but before assigning it we also modify the set by adding our own packages.

```nix
# release.nix
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

The `nixpkgs` value we return now from `release.nix` is the exact same package set as before,
but instead of having `haskellPackages` pointing to a pristine package set for `ghc-8.6.4` <sup>[1](#footnote-1)</sup>, it points to our
modified package set for ghc-8.4.4. `haskell.packages.ghc844` still points to the pristine package set for `ghc-8.4.4` - just try `nix-instantiate --eval -E 'haskell.packages.ghc844.package1' "<nixkpgs>"`, it will fail.

Now we can build and execute our package by running:

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

Or use it as a haskell dependency:

```bash
$ nix-shell -p "(import ./release.nix).haskellPackages.ghcWithPackages (pkgs: [ pkgs.package1 ])"
```

> WARNING
>
> You might get the following warning when building your projects:
>
> ```
> warning: dumping very large path (> 256 MiB); this may run out of memory
> ```
>
> When Nix evaluates the expression for your package, it will force the attribute `src` which is a Nix path
> to the source code of the package. In order for Nix to create a derivation for it, it needs to first store
> the source in the store and replace the path with the store path. Before copying the whole source though
> it will compute the hash for the whole subtree of the path and if it is already in the store it will just reuse that path.
>
> This is problematic for 2 reasons:
> 1. currently there is a [bug](https://github.com/NixOS/nix/issues/358) that causes the SHA computation to run in non-constant memory space
> 2. any files in the source tree that don't really represent source code are also taken into account.
>    An example are `.stack-work` folders, you might potentially have one for each package and they are typically huge, as they contain all build artefacts.
>
> A way to mitigate *2* is modifying the `src` attribute to take only the desired files into account. [nix-gitignore](https://github.com/siers/nix-gitignore) can be used to fix this.

<a id="footnote-1"><b>[1]</b></a> You can check the default by running `nix-instantiate --eval -E '(import (import ./pinned-nixpkgs.nix) {}).haskellPackages.ghc.version'`
