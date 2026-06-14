# The trunk-built static dist of the leptos frontend. It is embedded into
# the athenut-mint binary (see package.nix), so PUBLIC_API_URL stays empty:
# the app talks to the origin it is served from.
{ lib
, rustPlatform
, trunk
, wasm-bindgen-cli
, binaryen
, wasmClangEnv
}:

rustPlatform.buildRustPackage {
  pname = "athenut-frontend-dist";
  version = "0.1.0";

  src = lib.cleanSource ../athenut-frontend;

  cargoLock.lockFile = ../athenut-frontend/Cargo.lock;

  nativeBuildInputs = [
    trunk
    wasm-bindgen-cli
    binaryen
  ];

  env = {
    PUBLIC_API_URL = "";
    TRUNK_SKIP_VERSION_CHECK = "true";
    TRUNK_OFFLINE = "true";
    CARGO_PROFILE_RELEASE_OPT_LEVEL = "z";
    CARGO_PROFILE_RELEASE_LTO = "true";
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
  } // wasmClangEnv;

  buildPhase = ''
    runHook preBuild
    XDG_CACHE_HOME=$TMPDIR/cache trunk build --release --dist dist
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';

  doCheck = false;

  meta = with lib; {
    description = "Athenut - privacy-preserving search engine frontend (static dist)";
    license = licenses.mit;
  };
}
