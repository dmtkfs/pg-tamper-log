-- Audit_log table
CREATE TABLE audit_log (
  id         BIGSERIAL PRIMARY KEY,
  ts         TIMESTAMPTZ NOT NULL DEFAULT now(),
  event      JSONB        NOT NULL,
  prev_hash  TEXT,
  hash       TEXT         NOT NULL
);

-- Hashing trigger function
CREATE OR REPLACE FUNCTION audit_log_hash() RETURNS trigger AS $$
DECLARE
  last_hash TEXT;
BEGIN
  SELECT hash INTO last_hash
  FROM audit_log
  ORDER BY id DESC
  LIMIT 1;

  NEW.prev_hash := COALESCE(last_hash, '');
  NEW.hash := encode(digest(NEW.prev_hash || NEW.event::text, 'sha256'), 'hex');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER audit_log_chain
BEFORE INSERT ON audit_log
FOR EACH ROW
EXECUTE FUNCTION audit_log_hash();

-- View to detect tampering
CREATE OR REPLACE VIEW tamper_log_verify AS
SELECT id, ts, event, prev_hash, hash,
       CASE
         WHEN prev_hash != lag(hash) OVER (ORDER BY id)
         THEN 'MISMATCH'
         ELSE NULL
       END AS integrity_check
FROM audit_log;
