use pgrx::prelude::*;
use sha2::{Sha256, Digest};
use hex;

pgrx::pg_module_magic!();

#[pg_extern]
fn sha256_fast(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hex::encode(hasher.finalize())
}
