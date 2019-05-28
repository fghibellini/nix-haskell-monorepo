
# Testing the Docs

`docs/QUICKSTART.md`:

````markdown
# Hello

Welcome to our project

```
curl -XPOST http://localhost:3000/postOrder -d@- <<EOF
{ "cartId": "$(uuidgen)" }
EOF
```

and that's how you do it.
````

`nix/test-quickstart.nix`:

```nix
let

    nixpkgs = import <nixpkgs> {
        overlays = import ./overlays;
        config = {
            packageOverrides = pkgs: {
                haskellPackages = pkgs.haskellPackages.override {
                    overrides = self: super: {
                        order-processor = super.callCabal2nix "order-processor" ../code/order-processor {};
                    };
                };
            };
        };
    };

    make-test = import <nixpkgs/nixos/tests/make-test.nix>;

    post-order = nixpkgs.fcbScript { pattern = "curl"; path = ../docs/QUICKSTART.md; };

in

    make-test {

      nodes = { machine = { config, pkgs, ... }: { environment.systemPackages = [ nixpkgs.haskellPackages.order-processor ]; }; };

      testScript =
        ''
          startAll;
          $machine->waitForUnit("network.target");
          $machine->succeed("order-processor-exe &");

          # create the order
          $machine->waitUntilSucceeds("${post-order}");
          $machine->waitUntilSucceeds("[[ $(curl http://localhost:3000/orderCount) -eq 1 ]]");
        '';

    }
```

In the [next chapter](../docker) we will use Nix to automatically generate docker images for all our packages.
