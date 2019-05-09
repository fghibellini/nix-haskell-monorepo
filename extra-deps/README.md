
# Extra Deps

Nix provides us with a very extensive curated list of Haskell packages, but it
will often be the case that your project will depend on some package or package version that is not
available or that is marked as broken.

To implace the packages we want, we will use the same mechanism we used to add our monorepo packages.
The only difference is that the Nix expressions that we will use will reference remote source code.

Let's see an example. If we tried to use `grpc-etcd-client` as a dependency to our packages the build would break:

```
nix-shell -p '(import (import ./pinned-nixpkgs.nix) {}).haskell.packages.ghc844.ghcWithPackages (pkgs: [ pkgs.grpc-etcd-client ])'
error: Package ‘grpc-etcd-client-0.1.2.0’ in /nix/store/j9v72fi7jrkxgr3yib2xirmfsc440r5m-source/pkgs/development/haskell-modules/hackage-packages.nix:98443 is marked as broken, refusing to evaluate.

a) For `nixos-rebuild` you can set
  { nixpkgs.config.allowBroken = true; }
in configuration.nix to override this.

b) For `nix-env`, `nix-build`, `nix-shell` or any other Nix command you can add
  { allowBroken = true; }
to ~/.config/nixpkgs/config.nix.

(use '--show-trace' to show detailed location information)
```

The package is marked as broken. There is however an updated version on github - version `0.1.2.1`.
To fix this we simply need to make use of the handy `cabal2nix` utility once again.

```bash
$ cabal2nix https://github.com/fghibellini/etcd-grpc --subpath grpc-etcd-client 2>/dev/null
{ mkDerivation, base, bytestring, fetchgit, grpc-api-etcd, hpack
, http2-client, http2-client-grpc, lens, network, proto-lens
, proto-lens-runtime, stdenv
}:
mkDerivation {
  pname = "grpc-etcd-client";
  version = "0.1.2.1";
  src = fetchgit {
    url = "https://github.com/fghibellini/etcd-grpc";
    sha256 = "0dn9ds58f61xi6br9v1djr3hril7jbyvbcjhnsg382h1knarfa71";
    rev = "80ac296291a09be3eb70a9ea07677a575e4ec442";
    fetchSubmodules = true;
  };
  postUnpack = "sourceRoot+=/grpc-etcd-client; echo source root reset to $sourceRoot";
  libraryHaskellDepends = [
    base bytestring grpc-api-etcd http2-client http2-client-grpc lens
    network proto-lens proto-lens-runtime
  ];
  libraryToolDepends = [ hpack ];
  preConfigure = "hpack";
  homepage = "https://github.com/lucasdicioccio/etcd-grpc#readme";
  description = "gRPC client for etcd";
  license = stdenv.lib.licenses.bsd3;
}
```

Now all we have to do is replace the broken package `grpc-etcd-client` with ours. To do so we create a file `extra-deps.nix` (we will use this file to hold all our overrides):

```nix
let

    grpc-etcd-client = { mkDerivation, base, bytestring, fetchgit, grpc-api-etcd, hpack
	, http2-client, http2-client-grpc, lens, network, proto-lens
	, proto-lens-runtime, stdenv
	}:
	mkDerivation {
	  pname = "grpc-etcd-client";
	  version = "0.1.2.1";
	  src = fetchgit {
	    url = "https://github.com/fghibellini/etcd-grpc";
	    sha256 = "0dn9ds58f61xi6br9v1djr3hril7jbyvbcjhnsg382h1knarfa71";
	    rev = "80ac296291a09be3eb70a9ea07677a575e4ec442";
	    fetchSubmodules = true;
	  };
	  postUnpack = "sourceRoot+=/grpc-etcd-client; echo source root reset to $sourceRoot";
	  libraryHaskellDepends = [
	    base bytestring grpc-api-etcd http2-client http2-client-grpc lens
	    network proto-lens proto-lens-runtime
	  ];
	  libraryToolDepends = [ hpack ];
	  preConfigure = "hpack";
	  homepage = "https://github.com/lucasdicioccio/etcd-grpc#readme";
	  description = "gRPC client for etcd";
	  license = stdenv.lib.licenses.bsd3;
	};

in (super: {
    grpc-etcd-client = super.callPackage grpc-etcd-client {};
})
```

the above exported function is just the right transformation that we can apply with the `haskellPackages.override` function.

```nix
# release.nix
let

  nixpkgs = import (import ./pinned-nixpkgs.nix) { inherit config; };

  monorepo-pkgs = import ./packages.nix;
  extra-deps = import ./extra-deps.nix;

  config = {
    allowUnfree = true;
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskell.packages.ghc844.override {
        overrides = self: super: (extra-deps super) // (builtins.mapAttrs (name: value: super.callPackage value {}) monorepo-pkgs);
      };
    };
  };

in nixpkgs
```

TODO insert diff with previous release.nix

Sometimes `nixpkgs` will contain multiple versions of the same package. This is the case for example in our snapshot with the `servant` packages.
Our haskell package set has a `servant_0_16_0_1` attribute. We can make this the default servant (as opposed to `servant-0.15` <sup>[1](#footnote-1)</sup>) by reassigning it in our transformation function:

```nix
let

    grpc-etcd-client = { mkDerivation, base, bytestring, fetchgit, grpc-api-etcd, hpack
	, http2-client, http2-client-grpc, lens, network, proto-lens
	, proto-lens-runtime, stdenv
	}:
	mkDerivation {
	  pname = "grpc-etcd-client";
	  version = "0.1.2.1";
	  src = fetchgit {
	    url = "https://github.com/fghibellini/etcd-grpc";
	    sha256 = "0dn9ds58f61xi6br9v1djr3hril7jbyvbcjhnsg382h1knarfa71";
	    rev = "80ac296291a09be3eb70a9ea07677a575e4ec442";
	    fetchSubmodules = true;
	  };
	  postUnpack = "sourceRoot+=/grpc-etcd-client; echo source root reset to $sourceRoot";
	  libraryHaskellDepends = [
	    base bytestring grpc-api-etcd http2-client http2-client-grpc lens
	    network proto-lens proto-lens-runtime
	  ];
	  libraryToolDepends = [ hpack ];
	  preConfigure = "hpack";
	  homepage = "https://github.com/lucasdicioccio/etcd-grpc#readme";
	  description = "gRPC client for etcd";
	  license = stdenv.lib.licenses.bsd3;
	};

in (super: {
    grpc-etcd-client = super.callPackage grpc-etcd-client {};
    servant                  = super.servant_0_16_0_1;
    servant-server           = super.servant-server_0_16;
    servant-client           = super.servant-client_0_16;
    servant-client-core      = super.servant-client-core_0_16;
    servant-blaze            = super.servant-blaze_0_9;
})
```

Sometimes a package will simply have tests that won't succeed because they require some setup
but you know the library code is OK. Then what you can do is simply disable the tests on that one package like so:

```
let

    dontCheck = (import ./release.nix).haskell.lib.dontCheck;

    ...

in (super: {
    system-fileio = dontCheck super.system-fileio;
    ...
})
```

In the [next chapter](../system-deps) we will se how to add system dependencies to our packages.

<a id="footnote-1"><b>[1]</b></a> `nix-instantiate --eval -E '(import (import ./pinned-nixpkgs.nix) {}).haskell.packages.ghc844.servant.version'` evaluates to `"0.15"`
