
# shell.nix

[The nix haskell tutorial](https://github.com/Gabriel439/haskell-nix/tree/master/project0#building-with-cabal) explains how to use Nix to provision a shell environment,
in which you get all the tools required to build your package with Cabal.

Cabal newly features a new v2 API (currently exposed with the `new-` prefix) that allows you to build multi-package projects.
This is ideal for monorepos.

Ideally we would like to combine the above two mechanisms and have Nix provision an environment in which we would have a GHC with all
the dependencies of all our packages, such that the only task left to Cabal is actually building whatever we are working on.

> NOTE
>
> Cabal used to have an `--offline` flag that would assure it couldn't fetch any packages from the internet.
> It seems it [no longer works with the new API](https://github.com/haskell/cabal/issues/5346).
> If you really want to make sure Cabal is using the packages provided by Nix you can use the following hack ([source](https://github.com/haskell/cabal/issues/5783#issuecomment-445518839)):
>
> 1. Remove all the files and directories except `config` in the `~/.cabal` folder, so that any already fetched packages will be removed
> 2. Remove any `dist` folders that were results of previous `cabal` runs
> 3. Comment out the repository section in your `~/.cabal/config` like so:
> ```
> -- repository hackage.haskell.org
> --   url: http://hackage.haskell.org/
> --   secure: True
> --   root-keys:
> --   key-threshold: 3
> ```
>
> Now Cabal should really have no way to access packages other than the ones already installed with GHC.

## Cabal `new-*` commands

To make use of the new multi-package support, you have to declare a `cabal.project` file. In the trivial case
you will simply list the constituent packages like so:

```
packages: hello-world
          universe
```

If you now run `cabal new-build all` Cabal will first fetch all the dependencies of both `hello-world` and `universe` and it will then
build the packages in the correct order until everything is built. Instead of "all" you can also specify a single package and Cabal will only build the
very minimum to build that one package.

Which versions of the dependencies will Cabal fetch is a complicated topic and can be entirely avoided by using Nix.

> NOTE
>
> If you were already using Cabal to build your monorepo and you are specifying external dependencies explicitly,
> you will want to create a second `cabal.project` in the nix folder without those external deps.
> Then you will have to specify the `caba.project` file with all the cabal invocations. e.g.
> ```
> cabal new-configure --project-file ../nix/cabal.project && cabal new-build --project-file ../nix/cabal.project
> ```
> It is unfortunate that Cabal doesn't allow to specify the project file with an environment variable instead of a flag,
> since we can specify environment variables in shell.nix files.

# Nix as package provisioner

Every haskell derivation in Nix provides us with a `env` attribute.
If we try to create a shell with this attribute (e.g. `nix-shell -A haskellPackages.aeson.env "<nixpkgs>"`) we will end up with a GHC that has
all the dependencies of the given package already installed. When we subsequently run Cabal it will realize that there is no fetching to be done
and proceed to only build the requested package.

What we would like though in our case, is a the environment for a __set__ of packages.

`nix-shell` will by default try to read first a `shell.nix` file in the current directory to generate a shell.
We can greatly take advantage of this and add a `shell.nix` file to our `code` folder with the following contents:

```nix
# shell.nix
let

    nixpkgs = import ../nix/release.nix;
    monorepo-pkgs = import ../nix/monorepo.nix;

in

    nixpkgs.haskellPackages.shellFor {
        packages = p: builtins.attrValues monorepo-pkgs;
        buildInputs = [
            nixpkgs.haskellPackages.cabal-install
        ];
    }
```

Now any user can simply move to the folder containing our haskell packages and run `nix-shell` without any arguments and he will be
thrown in a shell with all the deps required to run a simple `cabal new-build all`.

```bash
$ cd code
$ nix-shell
cabal new-run hello-world-exe
Warning: No remote package servers have been specified. Usually you would have
one specified in the config file.
Resolving dependencies...
Build profile: -w ghc-8.6.4 -O1
In order, the following will be built (use -v for more details):
 - universe-0.2.0.0 (lib) (first run)
 - hello-world-0.1.0.0 (exe:hello-world-exe) (first run)
Configuring library for universe-0.2.0.0..
Preprocessing library for universe-0.2.0.0..
Building library for universe-0.2.0.0..
[1 of 1] Compiling Universe.World   ( src/Universe/World.hs, /Users/fghibellini/code/nix-haskell-monorepo/shell.nix/monorepo/code/dist-newstyle/build/x86_64-osx/ghc-8.6.4/universe-0.2.0.0/build/Universe/World.o )
Configuring executable 'hello-world-exe' for hello-world-0.1.0.0..
Preprocessing executable 'hello-world-exe' for hello-world-0.1.0.0..
Building executable 'hello-world-exe' for hello-world-0.1.0.0..
[1 of 1] Compiling Main             ( exe/Main.hs, /Users/fghibellini/code/nix-haskell-monorepo/shell.nix/monorepo/code/dist-newstyle/build/x86_64-osx/ghc-8.6.4/hello-world-0.1.0.0/x/hello-world-exe/build/hello-world-exe/hello-world-exe-tmp/Main.o )
Linking /Users/fghibellini/code/nix-haskell-monorepo/shell.nix/monorepo/code/dist-newstyle/build/x86_64-osx/ghc-8.6.4/hello-world-0.1.0.0/x/hello-world-exe/build/hello-world-exe/hello-world-exe ...
Hello WORLD!!!
```

You can also add the following to your `.gitlab-ci.yml` if you want to make sure the above command trio will always work:

```
nix-shell:
  stage: build-and-lint
  image: fghibellini/nix # https://github.com/fghibellini/nix-haskell-gitlab-runner
  allow_failure: true
  script:
    cd $CI_PROJECT_DIR/code && nix-shell --command 'cabal new-configure && cabal new-build all'
```

In the [next chapter](../setting-up-a-hydra-instance) we will see how to get up and running a NixOS machine with a Hydra daemon.

