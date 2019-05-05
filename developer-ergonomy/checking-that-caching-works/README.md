
# Checking That Caching Works

All the instantiation related commands (read building commands) support the `--dry-run` flag even though it's not documented.

```bash
nix-build --dry-run monorepo.nix
```

Such invocations will output two lists - first the list of derivations that will be fetched from caches and second the list of
all derivations that will be built from source.

```
TODO add example output
```

> NOTE
>
> While this is very usefull to debug caching issues.
> I haven't found any way to make this command ignore derivations that are already in the local store (I haven't managed to specify an alternative store).
> This is painfull when you finally manage to build your whole project and want to verify how much will your colleagues have to build vs. fetch from caches.
> My only solution was to start a Docker image with the project mounted and then running the above command such that I knew the machine's store was completely empty.
>
> ```
> docker run -it --rm -v $(readlink -f .):/monorepo -v $(readlink -f ~/.ssh):/root/.ssh fghibellini/nix:tar nix-build --dry-run /monorepo/nix/monorepo.nix
> ```
