let

    nix-markdown-snippets-overlay = import (builtins.fetchGit {
      url = "https://github.com/fghibellini/nix-markdown-snippets.git";
      ref = "master";
      rev = "94697784cea3f657718da174e081da70066429ea";
    });

    nixpkgs = import <nixpkgs> { overlays = [ nix-markdown-snippets-overlay ]; };

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
