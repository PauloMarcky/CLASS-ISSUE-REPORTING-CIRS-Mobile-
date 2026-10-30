-- Week 14 (SA8 / IA5) - secure integration. Run ONCE in MySQL Workbench, after 01 to 03.
-- Passwords are never stored. Only a bcrypt hash is kept (set by: npm run seed:passwords).

USE srms;

ALTER TABLE users
  ADD COLUMN password_hash VARCHAR(100) NULL,
  ADD COLUMN failed_logins INT UNSIGNED NOT NULL DEFAULT 0,
  ADD COLUMN locked_until  DATETIME NULL;