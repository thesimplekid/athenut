# Athenut Frontend

A privacy-preserving web search engine frontend powered by [Kagi](https://kagi.com/) search results and [Cashu](https://cashu.space/) ecash tokens. Users pay for searches with Bitcoin Lightning-funded Cashu tokens -- no accounts, no tracking.

This crate lives in the Athenut workspace. It is not deployed as a separate
service in production; Trunk builds it into static assets, and the
`athenut-mint` binary embeds and serves those assets.

## How it works

1. Top up your balance by paying a Lightning invoice, which mints Cashu tokens stored in your browser
2. Each search spends one token, sent to the backend in an `X-Cashu` header
3. The backend validates the token and returns search results
4. No accounts, no cookies, no server-side state

## Development

This project is a Rust WebAssembly app built with [Leptos](https://book.leptos.dev/) (client-side rendered), using [CDK](https://docs.rs/cdk) for the Cashu wallet and [Trunk](https://trunkrs.dev/) for bundling. Wallet state is persisted in the browser's localStorage behind CDK's `WalletDatabase` trait.

### With Nix (recommended)

From the repository root, enter the dev shell. It provides the Rust toolchain
with the `wasm32-unknown-unknown` target, Trunk, and wasm tooling:

```bash
nix develop
```

Then, from this directory:

```bash
trunk serve                                      # start dev server (localhost:5173)
trunk build                                      # development build into dist/
trunk build --release                            # production build for embedding
cargo check --target wasm32-unknown-unknown      # type-check the wasm app
cargo test                                       # native test suite
```

### With just

A [justfile](justfile) wraps the common commands (each recipe runs inside the dev shell, so they work from any shell):

```bash
just            # list recipes
just dev        # trunk serve (localhost:5173)
just build      # development build
just release    # production build
just check      # cargo check (wasm target)
just test       # native test suite
just clippy     # lint
just fmt        # format
just serve      # serve dist/ with SPA fallback on :3000
```

### Configuration

| Variable         | Default | Description                                                                             |
| ---------------- | ------- | --------------------------------------------------------------------------------------- |
| `PUBLIC_API_URL` | `""`    | Backend API URL. Empty string means same-origin (frontend and backend on same domain). |

`PUBLIC_API_URL` is read at compile time (`option_env!`), so export it before running trunk:

```bash
PUBLIC_API_URL="https://athenut.com" trunk serve
```

## Production Build

The production package is the combined `athenut-mint` binary. The root flake
builds this frontend first as `athenut-frontend-dist`, then passes that store
path to the mint build through `FRONTEND_DIST` so `rust-embed` can bake the UI
into the executable.

```bash
nix build .#athenut-mint
```

The flake also exposes `.#athenut-frontend-dist` for debugging the generated
static bundle, but deployment should use `.#athenut-mint` or the
`services.athenut-mint` NixOS module from the repository root.

## License

[MIT](LICENSE)
