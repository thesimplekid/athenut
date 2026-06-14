{ lib
, rustPlatform
, pkg-config
, protobuf
, frontendDist
}:

rustPlatform.buildRustPackage {
  pname = "athenut-mint";
  version = "0.1.0";

  src = lib.cleanSource ../athenut-mint;

  cargoLock.lockFile = ../athenut-mint/Cargo.lock;

  nativeBuildInputs = [
    pkg-config
    protobuf
  ];

  env = {
    PROTOC = "${protobuf}/bin/protoc";
    PROTOC_INCLUDE = "${protobuf}/include";
    # rust-embed bakes the trunk dist into the binary at compile time.
    FRONTEND_DIST = "${frontendDist}";
  };

  meta = with lib; {
    description = "Privacy-preserving paid web search using Cashu ecash (mint + frontend)";
    homepage = "https://github.com/thesimplekid/athenut";
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "athenut-mint";
  };
}
