# Athenut monorepo helpers (run inside `nix develop`)
set dotenv-load

mint_config := env_var_or_default("ATHENUT_CONFIG", "config.example.toml")
mint_work_dir := env_var_or_default("ATHENUT_WORK_DIR", "../.athenut-mint-dev")

default:
    @just --list

# Build the frontend dist (the mint build embeds it)
build-frontend:
    cd athenut-frontend && NO_COLOR=false trunk build --release

# Build the combined binary: mint API + embedded frontend
build: build-frontend
    cd athenut-mint && cargo build --release

# Type-check the mint
check:
    cd athenut-mint && cargo check

# Run the combined binary against a local config
run config=mint_config work_dir=mint_work_dir: build-frontend
    cd athenut-mint && cargo run -- --config "{{config}}" --work-dir "{{work_dir}}"
