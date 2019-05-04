{ mkDerivation, aeson, base, stdenv, text }:
mkDerivation {
  pname = "package2";
  version = "0.2.0.0";
  src = ../../code/package2;
  libraryHaskellDepends = [ aeson base text ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}
