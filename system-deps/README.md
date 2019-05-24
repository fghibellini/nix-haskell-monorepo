
# System Deps

Sometimes a haskell package will depend on a native library. In Nix this dependency has to be explicitly tracked.
In the simple case you would simply create a Nix expression for the haskell library and add the native library to the `librarySystemDepends` attribute list ([example](https://github.com/NixOS/nixpkgs/blob/1330269c1556e5600b1ea11061712cf649e72d4f/pkgs/development/haskell-modules/configuration-nix.nix#L383)) and add it as an input argument to your expression.
The `haskellPackages.callPackage` function would then take care of finding the appropriate package and supplying it.
As the following case-study shows it's sometimes easier said than done.

## Real-world scenario - ODBC

The haskell package `odbc` is marked as broken. But let's try to build it anyway to see where the failure lies:

```bash
$ nix-shell -p '(import (import ./pinned-nixpkgs.nix) { config = { allowBroken = true; }; }).haskell.packages.ghc844.ghcWithPackages (pkgs: [ pkgs.odbc ])'
these derivations will be built:
  /nix/store/g2nx6c6y8vbwbkz0vn30wh605gzfbm2r-odbc-0.2.2.drv
  /nix/store/bc5vl2axi5qrdz2jrsx1zb319zamh9ra-ghc-8.4.4-with-packages.drv
building '/nix/store/g2nx6c6y8vbwbkz0vn30wh605gzfbm2r-odbc-0.2.2.drv'...

...

cbits/odbc.c:7:10: error:  fatal error: 'odbcss.h' file not found
  |
7 | #include <odbcss.h>
  |          ^
#include <odbcss.h>
         ^~~~~~~~~~
1 error generated.
`cc' failed in phase `C Compiler'. (Exit code: 1)
builder for '/nix/store/g2nx6c6y8vbwbkz0vn30wh605gzfbm2r-odbc-0.2.2.drv' failed with exit code 1
cannot build derivation '/nix/store/bc5vl2axi5qrdz2jrsx1zb319zamh9ra-ghc-8.4.4-with-packages.drv': 1 dependencies couldn't be built
error: build of '/nix/store/bc5vl2axi5qrdz2jrsx1zb319zamh9ra-ghc-8.4.4-with-packages.drv' failed
```

As we can see the issue is not in some unmet haskell dependency, but the `C` compiler is failing to find a header file that is expected from a system library.
On non-Nix systems we would simply instruct the user to have the required library installed using the system's package manager, but with nix we have to feed
the library to the package that needs it.

We first need the derivations for the system dependencies - we will create a special file `system-deps.nix` for it. The file will export the 2 libraries that we need.
As of right now, setting up `unixODBC` on non-NixOS systems is quite challenging and so the [`system-deps.nix`](./system-deps.nix) is only for the strong soul. This will hopefully improved in the future.

```nix
# system-deps.nix
...
in rec {
  freetds = pkgs.freetds.override ...;
  ...
  unixODBC = pkgs.callPackage unixODBCDef ...;
}
```

Just like in [extra-deps](../extra-deps) we generate a nix expression for `odbc` and manually add `freetds` and `unixODBC` as dependenices in `extra-deps.nix`:

```nix
let

    odbc = { mkDerivation, async, base, bytestring, containers, deepseq
        , fetchgit, formatting, hspec, optparse-applicative, parsec
        , QuickCheck, semigroups, stdenv, template-haskell, text, time
        , transformers, unliftio-core, weigh,
	, unixODBC, freetds # <-------- CHANGE 1 - add native libs as inputs
        }:
        mkDerivation {
          pname = "odbc";
          version = "0.2.3";
          src = fetchgit {
            url = "https://github.com/fpco/odbc";
            sha256 = "0zg1sd160h6hz89w9ln4zjsn6f25nwm6jsj2w8byb638bivvhdvh";
            rev = "a2a3f57edfce2e3e3e25945f8564e6884b4faf38";
            fetchSubmodules = true;
          };
          isLibrary = true;
          isExecutable = true;
          libraryHaskellDepends = [
            async base bytestring containers deepseq formatting parsec
            semigroups template-haskell text time transformers unliftio-core
          ];
          librarySystemDepends = [ unixODBC freetds ]; # <-------- CHANGE 2 - specify the 2 libs as system dependencies
          executableHaskellDepends = [
            base bytestring optparse-applicative text
          ];
          testHaskellDepends = [
            base bytestring hspec parsec QuickCheck text time
          ];
          benchmarkHaskellDepends = [ async base text weigh ];
          homepage = "https://github.com/fpco/odbc";
          description = "Haskell binding to the ODBC API, aimed at SQL Server driver";
          license = stdenv.lib.licenses.bsd3;
        };

    ...

in {
    ...
    odbc = dontCheck (super.callPackage odbc {}); # we also have to disable the tests # <----------- CHANGE 3 - override the package and disable its tests
}
```

We then need to modify the `release.nix` file to fix the native libs:

```nix
...
  system-deps = import ./system-deps.nix;
  extra-deps = import ./extra-deps.nix;

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      inherit (system-deps { inherit pkgs; }) freetds unixODBC; # OVERRIDEN HERE
      haskellPackages = pkgs.haskell.packages.ghc864.override {
        overrides = self: super: ((extra-deps super) // builtins.mapAttrs (name: path: super.callCabal2nix name (gitignore path) {}) (import ./packages.nix));
      };
    };
  };
...
```

Where:

```nix
packageOverrides = pkgs: rec {
  inherit (system-deps { inherit pkgs; }) freetds unixODBC;
```

is the shorthand for:

```nix
packageOverrides = pkgs: let sps = system-deps { pkgs = pkgs; }; in rec {
  freetds = sps.freetds;
  unixODBC = sps.unixODBC;
```

In the [next chapter](../shell.nix) we will see how to create a virtual environment
for your devs.

