# compute-monorepo-deps.nix
# -------------------------
#
# This function expects a directory as an argument
# it will read all the files in the directory expecting them to be nix descriptions of haskell packages
# and it will return a list of string representing the union of all their dependencies combined omitting the dependencies they have between one another.
# "stdenv" and "mkDerivation" are also omitted for convenience.
#
# This is usefull when creating a shell.nix file for a monorepo.
#
# e.g.
# > $ ls -R ./packages
# > planner.nix  analytics.nix
# > $ head -n 1 ./packages/planner.nix
# > { mkDerivation, stdenv, algebraic-graphs, time, http2, analytics }:
# > $ head -n 1 ./packages/analytics.nix
# > { mkDerivation, stdenv, time, statistics }:
# > $ nix-instantiate --eval -E "((import <nixpkgs> {}).callPackage ./compute-monorepo-deps.nix {}) ./packages"
# > [ "algebraic-graphs" "time" "http2" "statistics" ]

{ lib }:

let

    unique = lib.lists.unique;

in

    dir:

        let
            files = builtins.readDir dir;
            project-names = builtins.attrValues (builtins.mapAttrs (name: value: builtins.elemAt (builtins.match "(.*)\\.nix" name) 0) files);
            args = builtins.mapAttrs (name: value: builtins.attrNames (builtins.functionArgs (import (dir + "/${name}")))) files;
            union = unique (builtins.concatLists (builtins.attrValues args));
        in
            builtins.filter (pkg: ! builtins.elem pkg (["stdenv" "mkDerivation"] ++ project-names)) union

