
# Testing the Docs


````markdown
Welcome to project "destroy_the_world".

Step 1 - send order:
```
curl -XPOST http://10.0.0.1:3920/persistOrder -H 'Content-type: application/json' -d@ <<EOF
{
  "cartId": "$(uuid-gen)",
  "date": "$(date ...)"
}
EOF
```

Step 2 - read order:
```
curl http://10.0.0.1:3920/readOrders/<order_id>
```
````

```nix
let

    release = import ../release.nix;
    inherit (import ../lib/utils.nix) make-test extract-snippet;

    # this is a bash script extracted from QUICKSTART.md
    send-random-order = extract-snippet { pattern = "curl.*-XPOST"; path = ../docs/QUICKSTART.md; filter = '' sed 's/10\.0\.0\.1:3920/localhost:9000/' ''; };

in

    make-test {

      nodes = { machine = { config, pkgs, ... }: { environment.systemPackages = [ release.haskellPackages.enode ]; }; };

      testScript =
        ''
          startAll;
          $machine->waitForUnit("network.target");
          $machine->succeed("package1-exe &");

          # create the order
          $machine->waitUntilSucceeds("${send-random-order}");
          $machine->waitUntilSucceeds("[[ $(curl http://localhost:9000/getOrderCount) -eq 1 ]]");
        '';

    }

```

In the [next chapter](../docker) we will use Nix to automatically generate docker images for all our packages.
