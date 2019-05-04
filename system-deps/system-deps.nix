let

    unixODBCDef = { stdenv, fetchurl, sysconfdir ? "/etc" }:
        stdenv.mkDerivation rec {
          name = "unixODBC-${version}";
          version = "2.3.7";

          src = fetchurl {
            url = "ftp://ftp.unixodbc.org/pub/unixODBC/${name}.tar.gz";
            sha256 = "0xry3sg497wly8f7715a7gwkn2k36bcap0mvzjw74jj53yx6kwa5";
          };

          configureFlags = [ "--disable-gui" "--sysconfdir=${sysconfdir}" ];

          meta = with stdenv.lib; {
            description = "ODBC driver manager for Unix";
            homepage = http://www.unixodbc.org/;
            license = licenses.lgpl2;
            platforms = platforms.unix;
          };
        };

    odbcFreetdsConf = { stdenv, freetds }:
        stdenv.mkDerivation rec {
          name = "odbc-sysconf-dir";
          unpackPhase = "true"; # no src
          buildPhase =
              ''
                  if [[ ! -f ${freetds}/lib/libtdsodbc.so ]]; then
                    echo "Freetds was not built with ODBC support." >&2
                    return 1
                  fi
                  cat > odbcinst.ini <<EOF
                  [ODBC Driver 13 for SQL Server]
                  Driver = ${freetds}/lib/libtdsodbc.so
                  EOF
              '';
          installPhase = ''
              mkdir $out
              cp ./odbcinst.ini $out
          '';
        };

in
{ pkgs }: let
  # This is used because freetds and unixODBC depend on each other.
  # freetds needs only the headers of unixODBC and so the following hack is possible:
  # 1. we build a version of unixODBC that doesn't depend of freetds.
  # 2. we pass the result to freetds to build
  # 3. the resulting freetds is then passed to a new unixODBC derivation
  #
  # We probably want to fix this upstream in nixpkgs
  # best solution is to implement something similar to this solution (dummy odbc) in nixpkgs for
  # all the unixODBC drivers and make freetds compatible with the odbcinst.ini generation mechanism
  # used by the other drivers in https://github.com/NixOS/nixpkgs/blob/139924308181c0ad1b7b27d1e22e15e25b04f7ba/nixos/modules/config/unix-odbc-drivers.nix
  dummyUnixOdbc = pkgs.callPackage unixODBCDef { sysconfdir = "/dummy"; };
in rec {
  freetds = pkgs.freetds.override { unixODBC = dummyUnixOdbc; };
  sysconfdir = pkgs.callPackage odbcFreetdsConf { freetds = freetds; };
  unixODBC = pkgs.callPackage unixODBCDef { sysconfdir = sysconfdir; };
}
