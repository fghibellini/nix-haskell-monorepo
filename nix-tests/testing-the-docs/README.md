
# Testing the Docs

> NOTE
>
> This requires you to add "https://github.com/fghibellini/nix-markdown-snippets.git" to your `allowed-uris` option if you run your evaluation in restricted mode (e.g. in hydra).

`docs/QUICKSTART.md`:

An often praised feature of Nix is that it allows you to seamlessly combine projects written in different programming languages.
What we don't emphasize enough, is that this also means that you can include even your markdown documents in your build process.
Here I show how you can use Nix to extract code snippets from your Markdown documentation and use it in your tests.

It is very valuable to have example calls in your documentation that show newcommers how to use your project.
Unfortunately remembering to keep the documentation up to date is very hard. Integrating your documentation in the CI process can
guarantee that your example code will always work.

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

Should `order-processor` change the format of its input and the docs were not updated, the CI will immediately
start complaining as the extracted curl request will fail.

See [nix-markdown-snippets](https://github.com/fghibellini/nix-markdown-snippets) for all the features of `fcbScript`.

In the [next chapter](../../docker) we will use Nix to automatically generate docker images for all our packages.

