
# Testing the Docs

> NOTE
>
> This requires you to add "https://github.com/fghibellini/nix-markdown-snippets.git" to your `allowed-uris` option if you run your evaluation in restricted mode (e.g. in hydra).

`docs/QUICKSTART.md`:

````markdown
# Hello

Welcome to our project

```
curl -f -XPOST http://localhost:3000/postOrder -H 'Content-type: application/json' -d@- <<EOF
{ "cartId": "$(uuidgen)" }
EOF
```

this request will persist an order in our system.
````

`nix/test-quickstart.nix`:

```nix
let

    nixpkgs = import (import ./pinned-nixpkgs.nix) {
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

    post-order = nixpkgs.fcbScript "post-order" { pattern = "curl"; path = ../docs/QUICKSTART.md; };

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
          $machine->succeed('[[ "$(curl -f http://localhost:3000/orderCount)" == "1" ]]');
        '';

    }
```

In the [next chapter](../docker) we will use Nix to automatically generate docker images for all our packages.
