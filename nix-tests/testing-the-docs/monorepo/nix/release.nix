let

    nixpkgs = import <nixpkgs> { overlays = import ./overlays; };

    post-number = nixpkgs.extract-snippet { pattern = "curl"; path = ../docs/QUICKSTART.md; };

in

    make-test {

      nodes = { machine = { config, pkgs, ... }: { environment.systemPackages = [ release.haskellPackages.enode ]; }; };

      testScript =
        ''
          startAll;
          $machine->waitForUnit("network.target");
          $machine->succeed("package1-exe &");

          # create the order
          $machine->waitUntilSucceeds("${post-number}");
          $machine->waitUntilSucceeds("[[ $(curl http://localhost:9000/getOrderCount) -eq 1 ]]");
        '';

    }
