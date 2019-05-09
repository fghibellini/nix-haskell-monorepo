
# Hydra Project Config

## Initial Hydra setup

**TODO** initializing the DB

**TODO** Creating the initial user

## Structure

> NOTE
>
> We're going to assume a monorepo of two haskell packages `package1` and `package2`.

Hydra uses the following entities:

1. project
2. jobset
3. job

A job represents the execution of the build of a single derivation (and its dependencies).
Instead of configuring single jobs Hydra has a notion of jobsets. To configure a jobset you first need a Nix expression that evaluates
to a derivation-valued attribute set. The attribute names are used as job names. Once you have this
expression in your repo you can create a jobset by specifying the git url to track and the path to this Nix expression file.
Jobsets are configured inside of projects which are just logical groupings of them.

**TODO** add screenshots of web UI

In practice you would have a structure similar to the following:

```
- monorepo [project]
   |
   +- main-build [jobset]
   |   |
   |   +- package1 [job]
   |   |
   |   +- package2 [job]
   |
   +- e2e-tests [jobset]
   |   |
   |   +- package1:test1 [job]
   |   |
   |   +- package2:test1 [job]
   |   |
   |   +- package1:special-test [job]
   |   |
   |   +- monorepo-test [job]
   |
   +- doc-validation [jobset]
       |
       +- dead-links [job]
       |
       +- user-handles-exist [job]
```

## Evaluation mode

The evaluation of the jobset expression is ran in pure-evaluation-mode.
From the Nix manual:

> Pure evaluation mode. This is a variant of the existing restricted evaluation mode. In pure mode, the Nix evaluator forbids access to anything that could cause different evaluations of the same command line arguments to produce a different result. This includes builtin functions such as builtins.getEnv, but more importantly, all filesystem or network access unless a content hash or commit hash is specified. For example, calls to builtins.fetchGit are only allowed if a rev attribute is specified.
>
> The goal of this feature is to enable true reproducibility and traceability of builds (including NixOS system configurations) at the evaluation level. For example, in the future, nixos-rebuild might build configurations from a Nix expression in a Git repository in pure mode. That expression might fetch other repositories such as Nixpkgs via builtins.fetchGit. The commit hash of the top-level repository then uniquely identifies a running system, and, in conjunction with that repository, allows it to be reproduced or modified.

For this reason evaluations that succeeded on your machine might fail on Hydra.
If the failure is cause by your expression trying to fetch some source-code repo, simply add it to the list of `allowed-uris` in the NixOS config file ([see](../setting-up-a-hydra-instance/)).


