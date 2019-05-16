
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
> docker run -it --rm -v $(readlink -f .):/monorepo -v $(readlink -f ~/.ssh):/root/.ssh fghibellini/nix nix-build --dry-run /monorepo/nix/monorepo.nix
> ```

## Nix cache debugging

You can test that the cache is reachable by querying the `/nix-cache-info` endpoint. This should return something along the lines of:

```
StoreDir: /nix/store
WantMassQuery: 1
Priority: 30
```

The info about a derivation is exposed at "/&lt;hash of the derivation&gt;.narinfo".
So if you're trying to build `/nix/store/d4vqy3sh0ngm9hsp7wwils7j6bms52xc-foundation-0.0.23` and your cache is at `http://10.0.0.3:5000` Nix will first
query `http://10.0.0.3:5000/d4vqy3sh0ngm9hsp7wwils7j6bms52xc.narinfo`. Assuming the cache contains the package the output will look something like:

```
StorePath: /nix/store/d4vqy3sh0ngm9hsp7wwils7j6bms52xc-foundation-0.0.23
URL: nar/d4vqy3sh0ngm9hsp7wwils7j6bms52xc.nar
Compression: none
NarHash: sha256:1nbv1cci1vrh1h2wxxbd0wdmh9jr47kkhz8207jjg9b9fw60vwsv
NarSize: 36341824
References: 0r9m0qi58jj14lv03ny7s4h76yg1rhfh-basement-0.0.10 681354n3k44r8z90m35hm8945vsp95h1-glibc-2.27 79gnjysbw3zkjqawx2ajs29w92q1v44a-ncurses-6.1-20190112 9b6qi566l7icp4z5l0fn86zfcbw8ws3f-gmp-6.1.2 d4vqy3sh0ngm9hsp7wwils7j6bms52xc-foundation-0.0.23 hrm96mjpxqdwlfzmilqi3029322cg1s9-foundation-0.0.23-doc icjdj6azjh3yblaghimlcznikjp0vraw-ghc-8.4.4
Deriver: fcv7anjpgh9hnznf3nir0nh1z5bjzp4m-foundation-0.0.23.drv
Sig: appuipieds-1:LFSKXu7VGR/4tIyNMVdQXLyilp0WMW6cylJJhNIdMdAGB+ZP975v9IWG9BXfG7PhHMuKtT4jmBj/tunyZ7E4Dg==
```

If the cache doesn't have the desired derivation it will simply return a 404.


In the [next chapter](../prefetch-nixpkgs.sh) we will write a script to mitigate first-time executions of Nix.
