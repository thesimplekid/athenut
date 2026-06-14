use axum::http::{header, StatusCode, Uri};
use axum::response::{IntoResponse, Response};
use rust_embed::RustEmbed;

/// Frontend assets built by trunk, embedded at compile time. FRONTEND_DIST
/// defaults to ../athenut-frontend/dist (see .cargo/config.toml) and is
/// overridden in the nix build to point at the trunk derivation output.
#[derive(RustEmbed)]
#[folder = "$FRONTEND_DIST"]
struct FrontendAssets;

/// Serve an embedded frontend asset, falling back to index.html so
/// client-side routes resolve on reload and direct navigation.
pub async fn serve_frontend(uri: Uri) -> Response {
    let path = uri.path().trim_start_matches('/');

    if !path.is_empty() {
        if let Some(file) = FrontendAssets::get(path) {
            return asset_response(path, file);
        }
    }

    index_html()
}

pub fn index_html() -> Response {
    match FrontendAssets::get("index.html") {
        Some(file) => asset_response("index.html", file),
        None => (StatusCode::NOT_FOUND, "frontend not bundled").into_response(),
    }
}

fn asset_response(path: &str, file: rust_embed::EmbeddedFile) -> Response {
    let mime = mime_guess::from_path(path).first_or_octet_stream();

    let cache_control = if path == "index.html" {
        // The entry point must revalidate so new deploys are picked up.
        "no-cache"
    } else if is_fingerprinted(path) {
        "public, max-age=31536000, immutable"
    } else {
        "public, max-age=3600"
    };

    (
        [
            (header::CONTENT_TYPE, mime.as_ref()),
            (header::CACHE_CONTROL, cache_control),
        ],
        file.data,
    )
        .into_response()
}

/// Trunk fingerprints bundled assets with a 16 hex digit hash segment,
/// e.g. athenut-frontend-74f6c427e46578d5_bg.wasm.
fn is_fingerprinted(path: &str) -> bool {
    let name = path.rsplit('/').next().unwrap_or(path);
    name.split(['-', '_', '.'])
        .any(|seg| seg.len() == 16 && seg.bytes().all(|b| b.is_ascii_hexdigit()))
}
