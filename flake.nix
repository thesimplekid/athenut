{
  description = "Athenut - privacy-preserving paid search (mint + frontend in one binary)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    {
      nixosModules.default = import ./nix/module.nix { inherit self; };
      nixosModules.athenut-mint = self.nixosModules.default;
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
          extensions = [ "rust-src" "rust-analyzer" ];
        };

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };

        # secp256k1-sys (C code) must be compiled for wasm32 with clang.
        # The wrapped NixOS clang injects native glibc flags, so use the
        # unwrapped one plus its builtin headers.
        wasmClangEnv = {
          CC_wasm32_unknown_unknown = "${pkgs.llvmPackages.clang-unwrapped}/bin/clang";
          CFLAGS_wasm32_unknown_unknown = "-I${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.versions.major pkgs.llvmPackages.libclang.version}/include";
          AR_wasm32_unknown_unknown = "${pkgs.llvmPackages.bintools-unwrapped}/bin/llvm-ar";
        };

        athenut-frontend-dist = pkgs.callPackage ./nix/frontend.nix {
          inherit rustPlatform wasmClangEnv;
        };

        athenut-mint = pkgs.callPackage ./nix/package.nix {
          frontendDist = athenut-frontend-dist;
        };
      in
      {
        packages = {
          inherit athenut-mint athenut-frontend-dist;
          default = athenut-mint;
        };

        devShells.default = pkgs.mkShell ({
          buildInputs = with pkgs; [
            rustToolchain

            # mint build deps
            pkg-config
            protobuf

            # wasm bundling
            trunk
            wasm-bindgen-cli
            binaryen

            # tooling
            just
            nixpkgs-fmt
            typos
          ];

          env = wasmClangEnv // {
            PROTOC = "${pkgs.protobuf}/bin/protoc";
            PROTOC_INCLUDE = "${pkgs.protobuf}/include";
          };

          shellHook = ''
            export TRUNK_SKIP_VERSION_CHECK=true
          '';
        });
      }
    );
}
