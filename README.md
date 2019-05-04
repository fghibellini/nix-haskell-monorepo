
# Nix Haskell Monorepo Tutorial

If you've got a haskell monorepo to manage, you've probably already thought a few times to yourself: *"Maan, wouldn't it be so much easier with Nix?"*

It actually wouldn't, but here's a tutorial anyway.

1. [pinned nixpkgs](./pinned-nixpkgs)
2. [monorepo nix expressions](./monorepo-nix-expressions)
3. [extra deps](./extra-deps)
4. native libs
5. shell.nix
6. code cleanup
7. setting up a hydra instance
8. hydra project config
9. nix tests
10. docker images
11. developer ergonomy
    1. checking that caching works
    2. prefetch-nixpkgs
12. possible improvements

# Why?

What can you gain by implementing this architecture:

- easy to write, ridiculously scalable, integration test-suites
- cached package-builds across machines
- self-contained project description - no need to list system dependencies
- easily bootstrappable local enrionment ??? TBD
- "reproducibility" - kinda

# What does "pragmatic" stand for here? Why don't you just read the whole Nix manual?!

If you've taken a university-level math course you will know that
elementary school math classes can hardly be considered as teachings about math.
You will probably still agree that it's kinda nice that most people
know how to add two numbers together.

Nix lacks a lot of elementary-level material.

