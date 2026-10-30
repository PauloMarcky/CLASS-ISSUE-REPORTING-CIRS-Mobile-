-- SRMS database - Step 1 (run this whole file in MySQL Workbench)
-- Workbench: File > Open SQL Script... > pick this file > click the lightning bolt.

CREATE DATABASE IF NOT EXISTS srms
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE srms;

-- Four roles from the project brief.
CREATE TABLE IF NOT EXISTS users (
  id         VARCHAR(10)  NOT NULL PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(150) NOT NULL UNIQUE,
  role       ENUM('student','faculty','facilitiesStaff','coordinator') NOT NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Same values as the Flutter enums (IssueCategory, IssuePriority, IssueStatus).
CREATE TABLE IF NOT EXISTS issues (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title          VARCHAR(120) NOT NULL,
  description    TEXT         NOT NULL,
  location       VARCHAR(120) NOT NULL,
  reporter_id    VARCHAR(10)  NOT NULL,
  category       ENUM('electrical','plumbing','airConditioning','furniture',
                      'itEquipment','cleanliness','safety','other') NULL,
  priority       ENUM('low','medium','high','urgent') NOT NULL DEFAULT 'medium',
  status         ENUM('reported','categorized','assigned','inProgress',
                      'resolved','verified','closed') NOT NULL DEFAULT 'reported',
  assigned_to_id VARCHAR(10)  NULL,
  is_escalated   TINYINT(1)   NOT NULL DEFAULT 0,
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_issue_reporter FOREIGN KEY (reporter_id) REFERENCES users(id),
  CONSTRAINT fk_issue_assignee FOREIGN KEY (assigned_to_id) REFERENCES users(id),
  INDEX idx_status (status),
  INDEX idx_location_category (location, category)
) ENGINE=InnoDB;

-- Fictional demo users (same four as the Flutter app). Passwords come in Week 14.
INSERT IGNORE INTO users (id, name, email, role) VALUES
  ('u1', 'Sam Student',      'student@srms.test',     'student'),
  ('u2', 'Fiona Faculty',    'faculty@srms.test',     'faculty'),
  ('u3', 'Felix Facilities', 'facilities@srms.test',  'facilitiesStaff'),
  ('u4', 'Cora Coordinator', 'coordinator@srms.test', 'coordinator');

-- A limited account for the API (so the app never uses the root account).
-- CHANGE the password below, and use the same one in your .env file.
CREATE USER IF NOT EXISTS 'srms_app'@'localhost' IDENTIFIED BY 'change_me';
GRANT SELECT, INSERT, UPDATE, DELETE ON srms.* TO 'srms_app'@'localhost';
FLUSH PRIVILEGES;