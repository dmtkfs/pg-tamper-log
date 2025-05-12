Below is the **raw README content** without any extra wrapping fences — copy **exactly what’s between the horizontal lines** into your `README.md`.
Every code block now opens and closes with matching ` ```sql ` / ` ```bash ` / ` ``` ` fences, so GitHub will render it correctly.

---

# pg\_tamperlog

> **Tamper‑evident, append‑only audit log for PostgreSQL**
> Each row’s SHA‑256 hash is chained to the previous row.
> A verification view can recompute the chain on demand, and an optional trigger blocks all `UPDATE` / `DELETE`, making the table write‑once.

---

## Features

| Capability                         | What it does                                                                                    |
| ---------------------------------- | ----------------------------------------------------------------------------------------------- |
| **`audit_log` table**              | Stores a JSON `event`, timestamp, previous row’s hash (`prev_hash`), and its own hash (`hash`). |
| **`audit_log_hash()` trigger**     | On every `INSERT` → calculates `prev_hash` + `hash` using `pgcrypto.digest()`.                  |
| **`tamper_log_verify` view**       | Recomputes the expected hash chain on the fly → flags any row with a bad `hash` or broken link. |
| **`audit_log_block_mods` trigger** | (Recommended) Rejects all `UPDATE` / `DELETE` attempts: *“audit\_log is append‑only”*.          |
| **Script‑only**                    | Pure SQL / PL‑pgSQL — no compiler toolchain needed.                                             |
| **Optional Rust add‑on**           | Future `pgrx` module can replace PL‑pgSQL hashing for high‑volume logs.                         |

---

## Quick start (dev mode)

```sql
-- One‑time setup
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Load the extension from your cloned repo
\i sql/pg_tamperlog--1.0.sql
```

### Insert some rows

```sql
INSERT INTO audit_log (event) VALUES
  ('{"user":"alice","action":"login"}'),
  ('{"user":"bob","action":"logout"}'),
  ('{"user":"charlie","action":"download"}');
```

### Simulate tampering (disable trigger, edit, re‑enable)

```sql
ALTER TABLE audit_log DISABLE TRIGGER audit_log_block_mods;

UPDATE audit_log
SET    event = '{"user":"eve","action":"tamper"}'
WHERE  id = 2;

ALTER TABLE audit_log ENABLE TRIGGER audit_log_block_mods;
```

### Detect the incident

```sql
SELECT id,
       integrity_check,
       hash      <> expected_hash      AS hash_mismatch,
       prev_hash <> expected_prev_hash AS chain_break
FROM   tamper_log_verify
WHERE  integrity_check IS NOT NULL;
```

| id | integrity\_check | hash\_mismatch | chain\_break |
| -- | ---------------- | -------------- | ------------ |
| 2  | **TAMPERED**     | `t`            | `f`          |
| 3  | **TAMPERED**     | `f`            | `t`          |

---

## One‑command demo

```bash
psql -U postgres -d mydb -f demo/demo.sql
```

The script inserts rows, tampers with one, shows the verifier output, and demonstrates that any further update is blocked.

---

## Installing as a real extension

1. Copy the two files to PostgreSQL’s extension directory:

```bash
# example on Linux
sudo cp sql/pg_tamperlog*.sql /usr/share/postgresql/16/extension/
sudo cp sql/pg_tamperlog.control /usr/share/postgresql/16/extension/
```

2. Then inside your database:

```sql
CREATE EXTENSION pgcrypto;
CREATE EXTENSION pg_tamperlog;
```

---

## Security notes

* **Append‑only protection** — Enabled by default; remove the `audit_log_block_mods` trigger if you *need* updates (but understand you’ll only detect tampering, not prevent it).
* **Performance** — `tamper_log_verify` rescans the full table; schedule it off‑hours or paginate on very large logs.
* **Rust add‑on** — A future `pgrx` helper will provide \~10 × faster hashing for high‑throughput workloads.

---

## License

MIT — see [`LICENSE`](./LICENSE).

> *This project is educational. Audit the code and threat‑model your environment before relying on it in production.*

---