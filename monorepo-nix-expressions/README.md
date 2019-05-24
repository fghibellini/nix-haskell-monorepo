
# Monorepo Nix Expressions

Now it's time to put our haskell code to work.
Each of our haskell packages should have a corresponding nix expression describing how to build it.
Fortunately `nixpkgs` contains a tool called `cabal2nix` that will generate a Nix file for each supplied cabal file.
Furthermore `haskellPackages` contains the handy function `callCabal2nix` that will invoke `cabal2nix` at evaluation time
and then call `callPackage` on the result.

The only remaining issue for us is that we would like to not have to pre-specify the list of cabal files.
To scan for haskell packages we can use some nix code. Handling paths in the Nix language is a bit cumbersome and
there's [quite a bit of magic involved](https://stackoverflow.com/a/43850372/3343425), but you don't have to concern
yourself too much about it since we can simply put [this function](./monorepo/nix/lib/utils.nix) into our utils module and never look at it again.

```bash
$ cd monorepo
$ tree .
.
├── code
│   ├── hello-world
│   │   ├── exe
│   │   │   └── Main.hs
│   │   └── hello-world.cabal
│   └── universe
│       ├── src
│       │   └── Universe
│       │       └── World.hs
│       └── universe.cabal
└── nix
    ├── lib
    │   └── utils.nix
    ├── monorepo.nix
    ├── packages.nix
    ├── pinned-nixpkgs.nix
    └── release.nix

$ cd nix
$ nix-instantiate --eval -E '(import ./lib/utils.nix).findHaskellPackages ../code' --json | jq
{
  "hello-world": "/nix/store/z2f4321ra1klnhbpindwvrpijq1gvdmj-hello-world",
  "universe": "/nix/store/5kj370166pqg4m9n10r4ll1ljhab684n-universe"
}

# Keep in mind that the function returns a set of Nix paths not strings.
# If we call the same function from within `nix repl` we will be presented with the actual paths.
# After evaluation just before outputting the result `nix-instantiate` copies the paths into the store
# and replaces the nix path with the store path.
$ nix repl
Welcome to Nix version 2.1.3. Type :? for help.

nix-repl> (import ./lib/utils.nix).findHaskellPackages ../code
{ hello-world = /Users/fghibellini/code/nix-haskell-monorepo/monorepo-nix-expressions/monorepo/code/hello-world; universe = /Users/fghibellini/code/nix-haskell-monorepo/monorepo-nix-expressions/monorepo/code/universe; }
```

Assuming our packages really do depend only on each other or their dependencies can be satisfied with packages from our pinned nixpkgs, we can already take them for a spin.
We will build our packages by inserting them into the haskell package set of Nixpkgs.
Nixpkgs accepts a config argument that (among other things) allows us to override packages in a functional (non-destructive) manner.
We override `haskellPackages` to be the package set for `ghc864` but before assigning it we also modify the set by adding our own packages.

```nix
# release.nix
let

  nixpkgs = import (import ./pinned-nixpkgs.nix) { inherit config; };

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskell.packages.ghc864.override {
        overrides = self: super: builtins.mapAttrs (name: path: super.callCabal2nix name path {}) (import ./packages.nix);
      };
    };
  };

in nixpkgs
```

The `nixpkgs` value we return now from `release.nix` is the exact same package set as before,
but instead of having `haskellPackages` pointing to a pristine package set for `ghc-8.6.4` <sup>[1](#footnote-1)</sup>, it points to our
modified package set for `ghc-8.6.4`. `haskell.packages.ghc864` still points to the pristine package set for `ghc-8.6.4` - just compare:

```bash
$ cd nix
$ nix-instantiate --eval -E '(import ./release.nix).haskellPackages.hello-world.pname'
"hello-world"
$ nix-instantiate --eval -E '(import ./release.nix).haskell.packages.ghc864.hello-world.pname'
error: attribute 'hello-world' missing, at (string):1:1
(use '--show-trace' to show detailed location information)
```

Now we can build and execute our package by running:

```bash
$ nix-build -A hello-world ./monorepo.nix
$ ./result/bin/hello-world-exe
Hello WORLD!!!
```

Or in an ephemeral shell environment:

```bash
$ nix-shell -p '((import ./release.nix).haskellPackages.hello-world)' --command hello-world-exe
Hello WORLD!!!
```

Or use it as a haskell dependency:

```bash
$ nix-shell -p '((import ./release.nix).haskellPackages.ghcWithPackages (pkgs: [ pkgs.universe ]))' --command "bash -c 'ghc-pkg list | grep universe'"
    universe-0.2.0.0
```

# Gitignore files

You might get the following warning when building your projects:

```
warning: dumping very large path (> 256 MiB); this may run out of memory
```

This is caused by the `src` attribute in the result of the `cabal2nix` invocation:

```
{ mkDerivation, aeson, base, stdenv, universe }:
mkDerivation {
  pname = "hello-world";
  version = "0.1.0.0";
  src = ../code/hello-world; # <----- THIS ATTRIBUTE
  isLibrary = false;
  isExecutable = true;
```

When Nix evaluates the expression for your package, it will force the attribute `src` which is a Nix path.
Nix paths are copied into the Nix store and they evaluate to the store path. Before performing the
copying though it will compute the SHA hash of the whole tree and check if it's not already present (if this was the case the path would be reused).

This is problematic for 2 reasons:
1. currently there is a [bug](https://github.com/NixOS/nix/issues/358) that causes the SHA computation to run in non-constant memory space
2. any files in the source tree that don't really represent source code are also taken into account.
   An example are `.stack-work` folders, you might potentially have one for each package and they are typically huge, as they contain all build artefacts.

A way to mitigate this is modifying the `src` attribute to take only the desired files into account.
We can simply pipe the package path through [nix-gitignore](https://github.com/siers/nix-gitignore) to make Nix ignore anything that is listed in our `.gitignore` file.

```nix
# release.nix
let

  nixpkgs = import (import ./pinned-nixpkgs.nix) { inherit config; };

  gitignore = nixpkgs.nix-gitignore.gitignoreSourcePure [ ../.gitignore ];

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskell.packages.ghc864.override {
        overrides = self: super: builtins.mapAttrs (name: path: super.callCabal2nix name (gitignore path) {}) (import ./packages.nix);
      };
    };
  };

in nixpkgs
```

In the [next chapter](../extra-deps) we will see how to override third-party haskell dependencies.

<a id="footnote-1"><b>[1]</b></a> You can check the default by running `nix-instantiate --eval -E '(import (import ./pinned-nixpkgs.nix) {}).haskellPackages.ghc.version'`

