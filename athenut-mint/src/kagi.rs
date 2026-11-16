use reqwest::{Client, RequestBuilder};
use serde_json::{json, Value};

fn search_request(client: &Client, token: &str, query: &str) -> RequestBuilder {
    client
        .post("https://kagi.com/api/v1/search")
        .bearer_auth(token)
        .json(&json!({
            "query": query,
            "filters": { "safe_search": false }
        }))
}

pub(crate) async fn search(token: &str, query: &str) -> Result<Value, reqwest::Error> {
    search_request(&Client::new(), token, query)
        .send()
        .await?
        .error_for_status()?
        .json()
        .await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn search_uses_v1_post_with_bearer_auth_and_json_query() {
        let query = "rust \"async\" & café";
        let request = search_request(&Client::new(), "test-token", query)
            .build()
            .unwrap();

        assert_eq!(request.method(), reqwest::Method::POST);
        assert_eq!(request.url().as_str(), "https://kagi.com/api/v1/search");
        assert_eq!(request.headers()["authorization"], "Bearer test-token");
        assert_eq!(request.headers()["content-type"], "application/json");
        let body: Value =
            serde_json::from_slice(request.body().unwrap().as_bytes().unwrap()).unwrap();
        assert_eq!(
            body,
            json!({ "query": query, "filters": { "safe_search": false } })
        );
    }
}
