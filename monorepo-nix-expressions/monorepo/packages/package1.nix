{ mkDerivation, aeson, base, package2, stdenv, text }:
mkDerivation {
  pname = "package1";
  version = "0.1.0.0";
  src = .././code/package1;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ aeson base package2 text ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}
