/*--------------------------------------------------------------------
Tamper‑evident audit log extension
pg_tamperlog--1.0.sql
--------------------------------------------------------------------*/

----------------------------------------------------------------------
-- 1.  TABLE
----------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    ts TIMESTAMPTZ NOT NULL DEFAULT now(),
    event JSONB NOT NULL,
    prev_hash TEXT,
    hash TEXT NOT NULL
);

----------------------------------------------------------------------
-- 2.  HASH‑ON‑INSERT TRIGGER FUNCTION
----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_log_hash()  RETURNS trigger AS $$
DECLARE
  last_hash TEXT;
BEGIN
  SELECT hash
    INTO last_hash
    FROM audit_log
   ORDER BY id DESC
   LIMIT 1;

  NEW.prev_hash := COALESCE(last_hash, '');
  NEW.hash      := encode(
                    digest(
                      (NEW.prev_hash || NEW.event::text)::bytea,
                      'sha256'
                    ),
                    'hex'
                  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------------
-- 3.  INSERT TRIGGER
----------------------------------------------------------------------
DROP TRIGGER IF EXISTS audit_log_chain ON audit_log;

CREATE TRIGGER audit_log_chain
BEFORE INSERT ON audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_hash();

----------------------------------------------------------------------
-- 4.  BLOCK ALL UPDATE / DELETE  (optional but recommended)
----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_log_no_mods()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is append‑only; modifications are not permitted';
END;
$$;

DROP TRIGGER IF EXISTS audit_log_block_mods ON audit_log;

CREATE TRIGGER audit_log_block_mods
BEFORE UPDATE OR DELETE ON audit_log
FOR EACH ROW EXECUTE FUNCTION audit_log_no_mods();

----------------------------------------------------------------------
-- 5.  VERIFY VIEW  (recomputes hashes + checks full chain)
----------------------------------------------------------------------

DROP VIEW IF EXISTS tamper_log_verify;

CREATE VIEW tamper_log_verify AS
WITH recomputed AS (
    SELECT
        id,
        ts,
        event,
        prev_hash,
        hash,
        encode(
          digest(
            (COALESCE(lag(hash) OVER (ORDER BY id), '') || event::text)::bytea,
            'sha256'
          ),
          'hex'
        ) AS expected_hash
    FROM audit_log
)
SELECT
    r.id,
    r.ts,
    r.event,
    r.prev_hash,
    r.hash,
    r.expected_hash,
    /* expected_prev_hash = recomputed hash of previous row */
    LAG(r.expected_hash) OVER (ORDER BY r.id) AS expected_prev_hash,
    CASE
      WHEN id = 1 THEN NULL
      WHEN r.hash      IS DISTINCT FROM r.expected_hash
        OR r.prev_hash IS DISTINCT FROM LAG(r.expected_hash) OVER (ORDER BY r.id)
      THEN 'TAMPERED'
      ELSE NULL
    END AS integrity_check
FROM   recomputed r
ORDER  BY r.id;