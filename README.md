
# Nix Haskell Monorepo Tutorial

I recently tried to create [Nix](https://nixos.org/) setup for our [Haskell](https://www.haskell.org/) monorepo at work. This tutorial documents the whole process.
This is still experimental and any feedback is very welcome. If you find it hard to understand some part just open an issue.

I absolutely recommend reading first [Gabriel's tutorial](https://github.com/Gabriel439/haskell-nix) on how to use Nix with Haskell in general.

Even though you end up with a project that can be fully built with Nix, [chapter 5. shell.nix](./shell.nix) describes how you can use Nix to only
provision your dependencies and use only Cabal and its `v2-` multi-package API to manage your build during development completely transparently.

1. [pinned nixpkgs](./pinned-nixpkgs)
2. [monorepo nix expressions](./monorepo-nix-expressions)
3. [extra deps](./extra-deps)
4. [system deps](./system-deps)
5. [shell.nix](./shell.nix)
6. [setting up a hydra instance](./setting-up-a-hydra-instance)
7. [hydra project config](./hydra-project-config)
8. [nix tests](./nix-tests)
    1. [simple test](./nix-tests/simple-test)
    2. [multiple machines](./nix-tests/multiple-machines)
    3. [generating tests](./nix-tests/generating-tests)
    4. [testing the docs](./nix-tests/testing-the-docs)
9. [docker images](./docker)
10. [developer ergonomy](./developer-ergonomy)
    1. [checking that caching works](./developer-ergonomy/checking-that-caching-works)
    2. [prefetch-nixpkgs.sh](./developer-ergonomy/prefetch-nixpkgs.sh)
    3. [IDEs](./developer-ergonomy/ides)
    4. making sure Cabal, Stack and Nix use the same versions

# Why?

What can you gain by following this tutorial:

- easy to write, integration test-suites
- cached package-builds across machines
- self-contained project description - no need to list system dependencies in a readme
- reproducibility
- easily bootstrappable local enrionment ??? TBD

