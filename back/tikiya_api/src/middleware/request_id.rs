use axum::http::Request;
use tower_http::trace::MakeSpan;
use tracing::Span;

pub struct RequestIdSpan;

impl<B> MakeSpan<B> for RequestIdSpan {
    fn make_span(&mut self, req: &Request<B>) -> Span {
        let method = req.method().as_str();
        let uri = req.uri().path();
        let id = simple_id(method, uri);
        tracing::info_span!("request", method = %method, uri = %uri, request_id = %id)
    }
}

fn simple_id(method: &str, uri: &str) -> String {
    use std::hash::{Hash, Hasher};
    use std::collections::hash_map::DefaultHasher;
    let mut h = DefaultHasher::new();
    method.hash(&mut h);
    uri.hash(&mut h);
    format!("{:x}", h.finish())
}