
# Generating tests

If we create a file listing our executables and the packages they reside in, we can map over them and generate a test-case for each of them.

To achieve this we will use the following helper function:

```nix
# nix/lib/utils.nix
let
    release = import ../release.nix;
    lib = release.lib;

    # e.g.:
    # > mapExecutables nixpkgs (pkg: prg: buildDockerForDervivationThatRunsCommand pkg prg) { my-db = { init = A; drop = B; }; my-cache = { insert = C; clear = D; }; }
    # { my-db:init = prg A; my-db:drop = prg B; my-cache:insert = prg C; my-cache:clear = prg D; }
    mapExecutables = fn:
        let execs = import ../executables.nix;
        in lib.listToAttrs (lib.flatten (lib.mapAttrsToList (haskellPkg: executables: map (exec: lib.nameValuePair ("${haskellPkg}:${exec}") (fn (builtins.getAttr haskellPkg release.haskellPackages) exec)) executables) execs));

    make-test = import "${import ../pinned-nixpkgs.nix}/nixos/tests/make-test.nix";

in {
    inherit mapExecutables make-test;
}
```

```nix
# nix/executables.nix
{
    package1 = [ "service1-exe" "service2-exe" ];
    package2 = [ "checker-exe" ];
}
```

With this you can write tests like this:

```nix
# nix/tests/etcd.nix
let

    inherit (import ../lib/utils.nix) make-test mapExecutables;

in

    mapExecutables (pkg: executable: make-test {

      nodes = { machine = { ... }: { environment.systemPackages = [ pkg ]; }; };

      testScript =
        ''
          $machine->start;
          $machine->waitForUnit("default.target");

	  # check that invoking the executable with the `--help` flag is supported
          $machine->succeed("${executable} --help");
        '';

    )}
```

This will generate 3 test cases. The more parametric we make our test specification the more tests we will be able to generate.

In the [next](../multiple-machines) chapter we will see how to write integration tests that span multiple machines.

