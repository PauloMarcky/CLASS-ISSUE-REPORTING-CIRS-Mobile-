-- SRMS database - Week 13 automation (run this whole file in MySQL Workbench)
-- Workbench: File > Open SQL Script... > pick this file > click the lightning bolt.

USE srms;

-- Work queue for automation steps that failed permanently (or ran out of retries).
-- A coordinator or facilities staff member reviews rows with status = 'open'.
-- Only the error CODE is stored, never the message, so no SQL or user text leaks.
CREATE TABLE IF NOT EXISTS automation_failures (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  job         VARCHAR(60)  NOT NULL,
  issue_id    INT UNSIGNED NULL,
  error_code  VARCHAR(60)  NOT NULL,
  reason      ENUM('permanent','retries_exhausted') NOT NULL,
  attempts    TINYINT UNSIGNED NOT NULL,
  status      ENUM('open','resolved') NOT NULL DEFAULT 'open',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP    NULL,
  resolved_by VARCHAR(10)  NULL,
  CONSTRAINT fk_failure_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE SET NULL,
  INDEX idx_failure_status (status)
) ENGINE=InnoDB;