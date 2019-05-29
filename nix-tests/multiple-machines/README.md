
# Tests involving multiple machines

Here we create a separate NixOS machine to run an [ETCD](https://coreos.com/etcd/) server that is used for service discovery and
we check that our service can succesfully register itself.

```nix
# test-etcd-registration.nix
let
    nixpkgs = import ./release.nix;
    make-test = import "${import ./pinned-nixpkgs.nix}/nixos/tests/make-test.nix";

in
    make-test {

      nodes =
          { machine = { ... }: { environment.systemPackages = [ nixpkgs.haskellPackages.serviceA ]; };
            etcdServer = { ... }: { services.etcd.enable = true; services.etcd.listenClientUrls = [ "http://0.0.0.0:2379" ]; networking.firewall.allowedTCPPorts = [ 2379 ]; };
          };

      testScript =
        ''
          startAll;
          $machine->waitForUnit("network.target");
          $etcdServer->waitForUnit("etcd.service");

          # start the service
          $machine->succeed("serviceA-exe --etcd-endpoint=http://etcdServer:2379 &");

          # assert that the service registered into etcd
          $etcdServer->waitUntilSucceeds("ETCDCTL_API=3 etcdctl get --prefix ''' | grep serviceA");
        '';

    }
```

[Next](../testing-the-docs) we will se how we can use Nix to include snippets of code from our docs into our tests.
