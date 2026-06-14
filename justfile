# Athenut monorepo helpers (run inside `nix develop`)

default:
    @just --list

# Build the frontend dist (the mint build embeds it)
build-frontend:
    cd athenut-frontend && trunk build --release

# Build the combined binary: mint API + embedded frontend
build: build-frontend
    cd athenut-mint && cargo build --release

# Type-check the mint
check:
    cd athenut-mint && cargo check

# Run the combined binary against a local config
run config="./athenut-mint/config.example.toml": build-frontend
    cd athenut-mint && cargo run -- --config {{config}}
