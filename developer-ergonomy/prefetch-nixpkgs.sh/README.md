
# prefetch-nixpkgs.sh

The `nixpkgs = import (import ./pinned-nixpkgs.nix) ...` portion of `release.nix`
uses `builtins.fetchGit` underneath, which will perform a synchronous git checkout of [Nixpkgs](https://github.com/NixOS/nixpkgs) at
evaluation time. This is a big issue in terms of first-time experience as in practice it means the user will run `nix-shell` and the command will hang in silence for minutes since it will be downloading the whole `Nixpkgs` repository.

You can alleviate this pain a little by using the following script:

```bash
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
```

The user will then have to run 2 commands:

```
./prefetch-nixpkgs.sh
nix-shell
```

But now it runs the first one with a clear expectation of wait-time. While the `nix-shell` invocation will pickup the shell build process straight away as
the result of the above checkout is cached in the store.

> POSSIBLE NIX IMPROVEMENT
>
> It would probably make sense for nix to cache a [Nixpkgs](https://github.com/NixOS/nixpkgs) checkout somewhere internally and
> resolve calls like the one above by simply first performing a fetch thus making sure all the new commits are present and then cloning
> into the store from it. This can be completely transparent to the user.

> NOTE
>
> In https://youtu.be/J4DgATIjx9E?t=1539 it is suggested to use `fetchTarball` instead of `fetchGit`
> as the download of the git repo represents roughly 600MB of data vs. 12MB of the tarball.
>
> This is unfortunately  not possible since `fetchTarball` is not available in restricted evaluation mode.

This concludes the tutorial (for now), I hope you found it helpful!
