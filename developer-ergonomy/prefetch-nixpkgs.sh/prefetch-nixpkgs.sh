#!/usr/bin/env bash
echo "Prefetching nixpkgs"
if RES=$(nix-instantiate --json --eval -E '"${import ./pinned-nixpkgs.nix}"'); then
  echo "Nixpkgs prefetched succesfully!"
  echo "Path:"
  echo "$RES" | sed -r 's/"//g'
else
  echo "prefetch failure"
  exit 1
fi

