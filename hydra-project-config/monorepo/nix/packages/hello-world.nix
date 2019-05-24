{ nix-gitignore, mkDerivation, aeson, base, stdenv, universe }:
mkDerivation {
  pname = "hello-world";
  version = "0.1.0.0";
  src = nix-gitignore.gitignoreSourcePure [ ../../../.gitignore ] ../../code/hello-world;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ aeson base universe ];
  license = stdenv.lib.licenses.unfree;
  hydraPlatforms = stdenv.lib.platforms.none;
}
