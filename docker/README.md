
# Docker

The following is all you need to generate one docker image per executable:

```nix
# docker.nix
let

    release = import ./release.nix;

    inherit (import ../lib/utils.nix) make-test mapExecutables;

in

    mapExecutables (pkg: executable: release.dockerTools.buildImage {
        name = "${executable}";
        config.Cmd = [ "${(release.haskell.lib.justStaticExecutables pkg)}/bin/${executable}" ];
    })
```

Here we're simply reusing the code from [../nix-tests](../nix-tests).

TODO releases?

In the [following chapter](../developer-ergonomy) we spend some time making sure that your less nix-invested colleagues
have a good experience too.
