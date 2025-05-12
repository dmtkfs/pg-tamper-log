# pg_tamperlog

> A tamper-evident, append-only log table for PostgreSQL.

This lightweight Postgres extension adds a secure `audit_log` table and a `BEFORE INSERT` trigger that chains each row to the previous one using a SHA‑256 hash. Any deletion or modification breaks the chain, making tampering detectable.

## Features

- `audit_log` table with `event` payload, timestamp, and hash chain
- Trigger that auto-calculates `prev_hash` and `hash` at insert time
- Optional `tamper_log_verify` view to scan for inconsistencies
- Script-only extension (no C), compatible with standard Postgres installs
- *(Optional add-on)* Rust-based hashing for performance using [pgrx](https://github.com/pgcentral/pgrx)

## Installation

```sql
-- Inside your database
CREATE EXTENSION pgcrypto;            -- Required for SHA-256
CREATE EXTENSION pg_tamperlog;       -- Assuming it's installed
```
Or manually run the SQL in sql/tamper_log--1.0.sql.

## Rust Extension

The Rust add-on will replace  the hashing logic with a native implementation via pgrx. Build instructions coming soon.

*This is an educational project. Please do not rely on it for production security without thorough review.*
