
# Nix Tests

```nix
# test-help-flag.nix
let
    nixpkgs = import ./release.nix;
    make-test = import "${import ./pinned-nixpkgs.nix}/nixos/tests/make-test.nix";

in
    make-test {

      nodes = { machine = { ... }: { environment.systemPackages = [ nixpkgs.haskellPackages.package1 ]; }; };

      testScript =
        ''
          $machine->start;
          $machine->waitForUnit("network.target");
	  # check that invoking the executable with the `--help` flag is supported
          $machine->succeed("package1-exe --help");
        '';

    }
```

You can run the test with:

```
nix-build ./test-help-flag.nix
```

TODO rerunning a succesfull test

