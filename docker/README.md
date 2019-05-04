
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

# TODO minimze closure ?

There's really nothing much else to say about this.
