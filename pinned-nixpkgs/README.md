
# Pinned Nixpkgs

The basic pillar of any nix expression is nixpkgs.
Nixpkgs is a nix expression providing the whole infrastructure
necessary to actually build a package.

## Pinning

You've probably seen derivations starting like:

```nix
{ nixpgs }:
...
```

or

```nix
let

    nixpkgs = import <nixpkgs> {};

...
```

Both of these approaches expect `nixpkgs` to be supplied from their environment, making the whole derivation non-reproducible.
The moment the environment changes its `nixpkgs`, the result of our expression will be completely different.

> NOTE
>
> Here we describe a technique where we let the Nix evaluator fetch a pre-specified commit of Nixpkgs.
> An alertnative using git submodules is described in [nixops tutorial](https://github.com/nh2/nixops-tutorial#nixops-tutorial).

To prevent this, we need to use a technique called __*nixpkg pinning*__.
It's nothing really scary - you simply specify an exact `nixpkg` commit in your expression and manually fetch it.
From version `2.0` nix has a handy function called [`builtins.fetchGit`](https://nixos.org/nix/manual/#builtin-fetchGit) that allows us to do just that!

> IMPORTANT!
>
> `Nixpkgs` also provides a [fetcher function](https://nixos.org/nixpkgs/manual/#sec-pkgs-fetchers) called `fetchgit`.
>
> DO NOT USE THAT ONE ! We will not go into explaining the difference for simplicity's sake.

```nix
# release.nix
let

    nixpkgs = import (import ./pinned-nixpkgs.nix) {};

in

    nixpkgs
```

In the next chapters we will modify `release.nix` to apply modifications to nixpgs.

```nix
# pinned-nixpkgs.nix
builtins.fetchGit {
    url = "https://github.com/NixOS/nixpkgs.git";
    rev = "98922fecef2b52002745c258a4a4b78c3c52a24b";
    ref = "master";
}
```

With this we can run:

```bash
nix-shell -p '(import ./release.nix).haskellPackages.ghcWithPackages (pkgs: [ pkgs.lenses pkgs.aeson ])'
```

Which will throw us into a prompt where we have `ghc` available with `lenses` and `diagrams` preinstalled.
It is important to emphasize that the two above files will always provide us with the exact same version of `ghc`, `lenses` and `diagrams` no matter the system, time or other circumstances under which the `nix-shell` command will be run.

So the output of the following command in the above provided shell should be the same even if run years from now (see [this](./INPUTS-EXPLAINED.md) to understand why it might differ).

```bash
ghc-pkg list
/nix/store/g1pp002k9ba0almdfdn4jdkfz81yr62s-ghc-8.6.4-with-packages/lib/ghc-8.6.4/package.conf.d
    Cabal-2.4.0.1
    aeson-1.4.2.0
    array-0.5.3.0
    attoparsec-0.13.2.2
    base-4.12.0.0
    base-compat-0.10.5
    binary-0.8.6.0
    bytestring-0.10.8.2
    containers-0.6.0.1
    deepseq-1.4.4.0
    directory-1.3.3.0
    dlist-0.8.0.6
    filepath-1.4.2.1
    ghc-8.6.4
    ghc-boot-8.6.4
    ghc-boot-th-8.6.4
    ghc-compact-0.1.0.0
    ghc-heap-8.6.4
    ghc-prim-0.5.3
    ghci-8.6.4
    hashable-1.2.7.0
    haskeline-0.7.4.3
    hpc-0.6.0.3
    integer-gmp-1.0.2.0
    integer-logarithms-1.0.3
    lenses-0.1.8
    libiserv-8.6.3
    mtl-2.2.2
    old-locale-1.0.0.7
    parsec-3.1.13.0
    pretty-1.1.3.6
    primitive-0.6.4.0
    process-1.6.5.0
    random-1.1
    rts-1.0
    scientific-0.3.6.2
    stm-2.5.0.0
    tagged-0.8.6
    template-haskell-2.14.0.0
    terminfo-0.4.1.2
    text-1.2.3.1
    th-abstraction-0.2.11.0
    time-1.8.0.2
    time-locale-compat-0.1.1.5
    transformers-0.5.6.2
    unix-2.7.2.2
    unordered-containers-0.2.9.0
    uuid-types-1.0.3
    vector-0.12.0.2
    xhtml-3000.2.2.1
```

In the [next chapter](../monorepo-nix-expressions) we will generate Nix expressions for our monorepo packages.

