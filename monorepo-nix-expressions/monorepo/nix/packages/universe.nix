{ mkDerivation, aeson, base, stdenv, text }:
mkDerivation {
  pname = "universe";
  version = "0.2.0.0";
  src = ../../code/universe;
  libraryHaskellDepends = [ aeson base text ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}
