# pg_tamperlog

**Tamper-evident, append-only audit logging for PostgreSQL**

`pg_tamperlog` is a PostgreSQL extension designed to securely store audit logs. Each log entry includes a SHA-256 hash linked to the previous entry, creating a hash chain. This makes any unauthorized changes immediately detectable. A Rust-based hashing function is available for improved performance.

---

## Features

- **Audit Log Table:** Stores events (`JSON`), timestamp, previous hash, and current hash.
- **Automatic Hashing:** Inserts automatically calculate hashes using triggers.
- **Rust Optimization (optional):** Fast hashing via the Rust extension (`pg_tamperlog_rust`).
- **Verification View:** Quickly identifies tampered log entries.
- **Modification Blocking:** Prevents unauthorized updates or deletions (append-only).
- **Easy to Install:** Pure SQL/PL-pgSQL, no special tools required.
- **Simple Upgrades:** Versioned extension upgrades supported.

---

## Quick Start

First-time setup in your PostgreSQL database:

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_tamperlog_rust; -- optional but recommended

-- Load the extension from source
\i sql/pg_tamperlog--1.1.sql
````

Insert audit log entries:

```sql
INSERT INTO audit_log (event) VALUES
  ('{"user":"alice","action":"login"}'),
  ('{"user":"bob","action":"logout"}');
```

Check for any tampering:

```sql
SELECT *
FROM tamper_log_verify
WHERE integrity_check IS NOT NULL;
```

If this query returns rows, tampering has occurred.

---

## Enable Rust Acceleration (Optional)

For faster hashing, build the Rust helper extension once per PostgreSQL installation:

```bash
cd rust/pg_tamperlog_rust

cargo pgrx package --release --pg-config "C:\Program Files\PostgreSQL\17\bin\pg_config.exe"

copy target\release\pg_tamperlog_rust.dll "C:\Program Files\PostgreSQL\17\lib"
copy pg_tamperlog_rust.control "C:\Program Files\PostgreSQL\17\share\extension"
```

Then enable it in your database:

```sql
CREATE EXTENSION pg_tamperlog_rust;
```

The extension will automatically use the faster Rust hashing function.

---

## Demo: See it in Action

Run a full demonstration:

```bash
psql -U postgres -d your_database -f demo/demo.sql
```

This demo:

1. Loads extensions.
2. Inserts sample log entries.
3. Simulates tampering.
4. Detects tampered entries.
5. Shows how the extension blocks further modifications.

---

## Installation as PostgreSQL Extension

Copy extension files to PostgreSQL's extension directory:

```bash
sudo cp sql/pg_tamperlog*.sql /usr/share/postgresql/17/extension/
sudo cp sql/pg_tamperlog.control /usr/share/postgresql/17/extension/
```

Enable in your database:

```sql
CREATE EXTENSION pgcrypto;
CREATE EXTENSION pg_tamperlog;
```

If upgrading from version 1.0:

```sql
ALTER EXTENSION pg_tamperlog UPDATE TO '1.1';
```

---

## Security Considerations

* **Append-only Protection:** By default, the extension blocks updates or deletes to ensure log integrity.
* **Performance:** The verification process checks the entire table. Run during off-peak hours if your log is large.
* **Administrative Controls:** Superusers could still drop or alter tables. Protect against this with offsite backups and proper role separation.

---

## License

MIT License. See [`LICENSE`](./LICENSE).

*Note: This project is intended for educational use. Please review carefully before using it in a production environment.*
