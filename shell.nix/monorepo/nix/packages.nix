let
  findHaskellPackages = (import ./lib/utils.nix).findHaskellPackages;
in
  findHaskellPackages ../code
