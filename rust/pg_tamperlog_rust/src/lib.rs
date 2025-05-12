use pgrx::prelude::*;
pg_module_magic!();

#[pg_extern]
fn sha256_fast(input: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hex::encode(hasher.finalize())
}
