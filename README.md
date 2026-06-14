# Athenut

Privacy-preserving paid web search using Cashu ecash.

This is a monorepo producing **one binary**: the mint serves the Cashu/search
API and the web frontend from the same axum server.

- [`athenut-mint/`](./athenut-mint) — Cashu mint and search API (axum). Embeds
  the frontend dist at compile time via `rust-embed` (`FRONTEND_DIST`, default
  `../athenut-frontend/dist`).
- [`athenut-frontend/`](./athenut-frontend) — Leptos (CSR) wallet/search UI,
  built with trunk. The wallet runs entirely in the browser.

The repository is also a Cargo workspace. `athenut-mint` is the default member
so root `cargo build`/`cargo check` commands target the native binary by
default. The frontend remains a workspace member for Rust tooling, but it is
bundled for production with Trunk before being embedded into the mint binary.

## Build

```sh
nix develop          # toolchain (rust + wasm target, trunk, protobuf, ...)
just build           # trunk build --release, then cargo build --release
```

Useful development checks:

```sh
cargo check                              # default workspace member: athenut-mint
cargo check -p athenut-frontend --target wasm32-unknown-unknown
cargo test -p athenut-frontend
```

Or with nix directly:

```sh
nix build .#athenut-mint     # combined binary (default package)
```

## Deploy (NixOS)

One module runs the whole thing:

```nix
{
  imports = [ athenut.nixosModules.default ];

  services.athenut-mint = {
    enable = true;
    configFile = "/run/secrets/athenut-mint.toml";
  };
}
```

### Upgrading from the two-service setup

The mint now serves the frontend itself, so the old separate
`services.athenut-frontend` is gone. When moving an existing host onto this
repo:

- **Remove** the `services.athenut-frontend` block and its flake input.
- **Repoint your reverse proxy** at the mint's listen port — the UI and the
  API are now served from the same origin (the standalone frontend port, e.g.
  3000, no longer exists).

`services.athenut-mint` keeps the same options, service name, user and state
directory (`/var/lib/athenut-mint`), so the mint's on-disk database carries
over. The binary also moves from the cdk 0.15 fork to cdk 0.17.0; cdk runs its
own schema migrations on first start. Back up `/var/lib/athenut-mint` before
the first upgrade.
