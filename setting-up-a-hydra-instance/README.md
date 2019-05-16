
# Setting Up a Hydra Instance

While you can run Hydra on your own laptop, in a team it definitely makes sense to
setup a dedicated machine for it.
This machine will then act as the CI and as a Nix cache for all your devs.

First you need to go through the [NixOS installation process](https://nixos.org/nixos/manual/index.html#sec-installation).

The last steps of the process are:

```
nixos-generate-config --root /mnt     # generate template of /etc/nixos config files
vim /mnt/etc/nixos/configuration.nix  # edit the config
nixos-install                         # build the system
reboot                                # boot into it
```

Once you generate the NixOS config file (first of the above commands), you will want to modify your `configuration.nix` to reasemble
the one in [./hydra](./hydra) and include the files that it references.
Then run `nixos-install` and you're ready to reboot.

> NOTE
>
> When running any command that will use the above config file you will get a warning:
>
> ```
> warning: unknown setting 'allowed-uris'
> ```
>
> This is a [bug](https://github.com/NixOS/nix/issues/2480), but the config works just fine - you can safely ignore it.

The [configuration.nix](./hydra/configuration.nix) file is annotated with comments, so I recommend spending some time reading it.

You can fork the above config at https://github.com/fghibellini/hydra-nixos-server.

## Adding the Hydra instance as a cache

Now on your client machines you have to modify your `/etc/nix/nix.conf` file to:

```
binary-caches = http://10.0.0.25:5000/ http://cache.nixos.org/
require-sigs = false
```

Where `10.0.0.25` is the IP address of your Hydra instance.

# TODO Darwin caching

TODO darwin builder

TODO cover `nix copy --to ssh://appuipieds $(nix-build shell.nix)`


Now that we have a NixOS machine up and running we can proceed to the [next chapter](../hydra-project-config) where
we configure Hydra to automatically run our builds.
