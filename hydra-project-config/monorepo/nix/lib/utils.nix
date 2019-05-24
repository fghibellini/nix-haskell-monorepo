let
    # accepts a path as input
    # it will traverse the directory tree starting at `root`
    # the result is an attribute set, where the values are paths
    # of directories directly containing cabal files.
    # the keys are the names of the packages.
    # hidden folders and blacklisted folders will be skipped
    findHaskellPackages = root:
        let items = builtins.readDir root;
            fn = file: type:
                if type == "directory" && isNull (builtins.match "\\..*" file) && !(builtins.elem file ["dist" "dist-new"]) then (findHaskellPackages (root + (/. + file)))
                else (if type == "regular" then (let m = (builtins.match "(.*)\\.cabal" file); in if !(isNull m) then { "${builtins.elemAt m 0}" = root; } else {})
                      else {});
        in builtins.foldl' (x: y: x // y) {} (builtins.attrValues (builtins.mapAttrs fn items));

in {
    inherit findHaskellPackages;
}
