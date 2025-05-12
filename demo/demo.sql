/*------------------------------------------------------------------
demo/demo.sql  – Showcase pg_tamperlog in action
------------------------------------------------------------------*/

-- 0. Prereqs (first run only)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Load the extension from source (dev mode)
\i sql/pg_tamperlog--1.0.sql

-- 2. Reset any previous demo data
TRUNCATE audit_log RESTART IDENTITY;

-- 3. Insert three clean audit events
INSERT INTO audit_log (event) VALUES
  ('{"user":"alice","action":"login"}'),
  ('{"user":"bob","action":"logout"}'),
  ('{"user":"charlie","action":"download"}');

SELECT '--- Current log state ---' AS msg;

TABLE audit_log;

-- 4. ⚠️  Simulate an attacker who edits row 2
--    We must disable the "no‑mods" trigger briefly
ALTER TABLE audit_log DISABLE TRIGGER audit_log_block_mods;

UPDATE audit_log
SET
    event = '{"user":"eve","action":"tamper"}'
WHERE
    id = 2;

ALTER TABLE audit_log ENABLE TRIGGER audit_log_block_mods;

SELECT '--- After tampering ---' AS msg;

TABLE audit_log;

-- 5. Run the verifier: should flag rows 2 and 3
SELECT '--- Tamper detection ---' AS msg;

SELECT
    id,
    integrity_check,
    hash <> expected_hash AS hash_mismatch,
    prev_hash <> expected_prev_hash AS chain_break
FROM tamper_log_verify
WHERE
    integrity_check IS NOT NULL;

-- 6. Show that further tampering is *blocked*
\echo
\echo 'Attempting a second UPDATE (should fail because trigger is back on):'
\echo

DO $$
BEGIN
  BEGIN
    UPDATE audit_log SET event = '{"user":"mallory","action":"blocked"}' WHERE id = 3;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Caught expected error: %', SQLERRM;
  END;
END;
$$;