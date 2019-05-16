let

    grpc-etcd-client = { mkDerivation, base, bytestring, fetchgit, grpc-api-etcd, hpack
    , http2-client, http2-client-grpc, lens, network, proto-lens
    , proto-lens-runtime, stdenv
    }:
    mkDerivation {
      pname = "grpc-etcd-client";
      version = "0.1.2.1";
      src = fetchgit {
        url = "https://github.com/fghibellini/etcd-grpc";
        sha256 = "0dn9ds58f61xi6br9v1djr3hril7jbyvbcjhnsg382h1knarfa71";
        rev = "80ac296291a09be3eb70a9ea07677a575e4ec442";
        fetchSubmodules = true;
      };
      postUnpack = "sourceRoot+=/grpc-etcd-client; echo source root reset to $sourceRoot";
      libraryHaskellDepends = [
        base bytestring grpc-api-etcd http2-client http2-client-grpc lens
        network proto-lens proto-lens-runtime
      ];
      libraryToolDepends = [ hpack ];
      preConfigure = "hpack";
      homepage = "https://github.com/lucasdicioccio/etcd-grpc#readme";
      description = "gRPC client for etcd";
      license = stdenv.lib.licenses.bsd3;
    };

in (super: {
    grpc-etcd-client = super.callPackage grpc-etcd-client {};
})
