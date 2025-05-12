-- demo.sql
-- Demo for pg_tamperlog

-- Load required extension (one-time)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Load the tamperlog extension (for dev)
\i sql/pg_tamperlog--1.0.sql

-- Clear any existing data
TRUNCATE audit_log;

-- Insert example entries
INSERT INTO audit_log (event) VALUES
  ('{"user":"alice","action":"login"}'),
  ('{"user":"bob","action":"logout"}'),
  ('{"user":"charlie","action":"download"}');

-- Check full table
SELECT * FROM audit_log;

-- Simulate tampering
UPDATE audit_log
SET
    event = '{"user":"eve","action":"tamper"}'
WHERE
    id = 2;

-- Verify chain integrity
SELECT * FROM tamper_log_verify;