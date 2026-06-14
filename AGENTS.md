# Repository Guidelines

## Project Structure & Module Organization

Athenut is a Rust Cargo workspace that builds one combined service. The default workspace member is `athenut-mint/`, an Axum Cashu mint and search API that embeds the frontend at compile time. `athenut-frontend/` is a Leptos CSR WebAssembly app bundled by Trunk. Shared build and deployment logic lives in `nix/`, `flake.nix`, and the root `justfile`.

Key paths:
- `athenut-mint/src/`: API, mint, config, MPP, frontend embedding, and route handlers.
- `athenut-frontend/src/`: Leptos app state, wallet, storage, components, and pages.
- `athenut-frontend/assets/`, `static/`, `styles/`: frontend images, copied static files, and CSS.
- `athenut-mint/config.example.toml`: local service configuration template.

## Build, Test, and Development Commands

Use the Nix shell for the expected Rust, wasm, Trunk, and protobuf toolchain:

```bash
nix develop
just build        # build frontend dist, then release-build the mint binary
just check        # cargo check for athenut-mint
just run          # build frontend, then run mint with config.example.toml
cargo test -p athenut-frontend
cargo check -p athenut-frontend --target wasm32-unknown-unknown
nix build .#athenut-mint
```

Frontend-only helpers are in `athenut-frontend/justfile`, including `just dev`, `just test`, `just clippy`, and `just fmt`.

## Coding Style & Naming Conventions

Use Rust 2021 style and `cargo fmt`. Keep modules focused by domain: route handlers in `search_route_handlers.rs`, payment protocol code in `mpp.rs`, UI routes under `src/pages/`, and reusable UI in `src/components/`. Leptos components use `PascalCase`; Rust modules, files, functions, and variables use `snake_case`. CSS lives in `athenut-frontend/styles/main.css`; scope page-specific rules under a `.page-*` wrapper.

## Testing Guidelines

Run targeted package tests before submitting changes. Use native `cargo test` for frontend wallet/storage tests and `cargo check --target wasm32-unknown-unknown` for wasm compatibility. Add focused unit tests near the code they cover when changing wallet state, proof handling, config parsing, or payment/search behavior.

## Commit & Pull Request Guidelines

This is a Jujutsu-backed workspace; check `.jj/` and prefer `jj status`, `jj diff`, and `jj log` for local VCS work. Existing history is minimal, so use concise, imperative commit descriptions such as `feat: add search receipt handling` or `fix: validate mint config`.

Pull requests should include a short problem/solution summary, test commands run, linked issues when applicable, and screenshots or recordings for visible frontend changes. Note config, migration, or deployment impact explicitly.

## Security & Configuration Tips

Do not commit real mnemonics, wallet seeds, Kagi API keys, or production config. Use `athenut-mint/config.example.toml` as a template and manage secrets outside the repository.
