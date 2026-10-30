-- SRMS database - Week 13 audit trail (run this whole file in MySQL Workbench)
USE srms;

-- One row per automated or manual state change, so every change is traceable.
CREATE TABLE IF NOT EXISTS issue_events (
  id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  issue_id   INT UNSIGNED NOT NULL,
  event      VARCHAR(40)  NOT NULL,   -- created, routed, escalated
  actor      VARCHAR(20)  NOT NULL,   -- user id, or 'system' for automation
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_event_issue FOREIGN KEY (issue_id) REFERENCES issues(id) ON DELETE CASCADE,
  INDEX idx_event_issue (issue_id)
) ENGINE=InnoDB;

-- Lets the escalation job use an index and the app prove when escalation happened.
ALTER TABLE issues ADD COLUMN escalated_at TIMESTAMP NULL;
