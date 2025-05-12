# pg-tamper-log
A tamper-evident audit log table for PostgreSQL. Each row includes a cryptographic hash chaining back to the previous row, making deletions or edits detectable. Includes a BEFORE INSERT trigger and optional Rust acceleration.
