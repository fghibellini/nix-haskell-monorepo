
# Nix Tests

> NOTE
>
> Running the tests is currently only supported on Linux.

```nix
# test-etcd-registration.nix
let
    nixpkgs = import ./release.nix;
    make-test = import "${import ./pinned-nixpkgs.nix}/nixos/tests/make-test.nix";

in
    make-test {

      nodes =
          { machine = { config, ... }: { environment.systemPackages = [ nixpkgs.haskellPackages.package1 ]; };
            etcdServer = { ... }: { services.etcd.enable = true; services.etcd.listenClientUrls = [ "http://0.0.0.0:2379" ]; networking.firewall.allowedTCPPorts = [ 2379 ]; };
          };

      testScript =
        ''
          startAll;
          $machine->waitForUnit("network.target");
          $etcdServer->waitForUnit("etcd.service");

          # start the service
          $machine->succeed("package1-exe --etcd-endpoint=http://etcdServer:2379 &");

          # assert that the service registered into etcd
          $etcdServer->waitUntilSucceeds("ETCDCTL_API=3 etcdctl get --prefix ''' | grep enode");
        '';

    }
```

You can run the test with:

```
nix-build ./test-etcd-registration.nix
```

In the [next chapter](../docker) we will use Nix to automatically generate docker images for all our packages.

