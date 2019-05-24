{ nix-gitignore, mkDerivation, aeson, base, stdenv, text }:
mkDerivation {
  pname = "universe";
  version = "0.2.0.0";
  src = nix-gitignore.gitignoreSourcePure [ ../../../.gitignore ] ../../code/universe;
  libraryHaskellDepends = [ aeson base text ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}
