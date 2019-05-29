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
