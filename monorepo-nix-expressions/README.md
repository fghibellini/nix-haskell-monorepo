
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
    │   └── src
    └── package2
        ├── package2.cabal
        └── src

$ ../generate-packages.sh ../code

$ tree .
.
├── code
│   ├── package1
│   │   ├── package1.cabal
│   │   └── src
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
