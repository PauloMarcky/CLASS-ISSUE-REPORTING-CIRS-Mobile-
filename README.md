# SRMS - Classroom Issue Reporting System

A modern, secure, and automated Flutter Web application with a Node.js backend and MySQL database, designed to streamline the reporting, routing, and resolution of classroom facility issues.

## Features

- Modern UI/UX: Clean, responsive Material 3 design with intuitive state management and role-based dashboards.
- Automated Routing: Rule-based keyword detection automatically categorizes issues and assigns them to the correct maintenance team.
- Duplicate Detection: Prevents redundant reports for the same location and category within a configurable time window.
- Aging Escalation: Scheduled background jobs automatically flag unassigned issues that have been open for over 24 hours.
- Resilient Automation: Bounded retry policies with exponential backoff for transient failures, and a human-review queue for permanent failures.
- Secure Authentication: JWT-based authentication, bcrypt password hashing, rate limiting, and strict role-based access control (RBAC).
- Audit Trail: Every state change and automation event is logged for full traceability.

## Project Structure

- `lib/` - Flutter Web and Android frontend.
- `backend/` - Node.js/Express API and backend tests.
- `backend/sql/` - MySQL schema and automation setup.
- `test/` - Flutter widget/API client tests.
- `scripts/` - Evidence helper scripts.
- `docs/` - Assessment documents, diagrams, reports, and evidence.
- `docs/week13/` - Week 13 Word artifacts.
- `docs/week15_ia6/` - Week 15 test and hardening deliverables.

## Setup Instructions

### 1. Database (MySQL)
Run these scripts in order in MySQL Workbench (File > Open SQL Script > Execute):
1. backend/sql/01_schema.sql (Edit the srms_app password in this file before running)
2. backend/sql/02_automation.sql
3. backend/sql/03_week13_audit.sql
4. backend/sql/04_week14_security.sql

### 2. Backend API
    cd backend
    copy .env.example .env
    (Edit .env and set DB_PASSWORD to match the password you chose in 01_schema.sql)
    (Set JWT_SECRET to a random string of at least 32 characters)

    npm install
    npm test                    (Run backend automation and security tests, no DB needed)
    npm run demo                (Generate retry/recovery evidence, no DB needed)
    npm run seed:passwords      (Set demo passwords, requires SEED_DEMO_PASSWORD env var)
    npm start                   (Starts server on http://localhost:3000)

Verify the API is running by visiting http://localhost:3000/api/health

### 3. Flutter Web Frontend
    (From the project root srms/)
    copy dart_defines.example.json dart_defines.json
    flutter pub get
    flutter test                (Run widget and API client tests)
    flutter run -d chrome --dart-define-from-file=dart_defines.json

For Android Emulator, keep the backend running with `npm start` and run:

    flutter run -d emulator-5554 --dart-define-from-file=dart_defines.json

The Android emulator reaches the Windows host through `10.0.2.2`, which is
the API address in `dart_defines.json`. A physical Android device must use the
Windows computer's local-network IP address instead, with both devices on the
same network.

## Demo Accounts

The system includes four fictional prototype accounts. Use the password Passw0rd! for all of them.

| Role | Email | Permissions |
|---|---|---|
| Student | student@srms.test | Report issues, view own issues, verify resolutions. |
| Faculty | faculty@srms.test | Report issues, view own issues, verify resolutions. |
| Facilities Staff | facilities@srms.test | View all issues, update repair progress, review automation failures. |
| Coordinator | coordinator@srms.test | Full access: categorize, assign, close issues, review automation failures. |

## Security and Configuration

- Never commit .env or dart_defines.json to version control.
- The API enforces CORS, Helmet security headers, and rate limiting on all /api routes.
- Passwords are hashed using bcrypt with a cost factor of 12.
- Sensitive fields (email, description, passwords) are automatically redacted in structured logs.

## Documentation and Evidence

- Automation Decisions: See docs/week13_sa7.md for workflow boundaries, retry policies, and API contracts.
- Test Evidence: Run npm test and flutter test to generate the required testing artifacts for IA6.
- Week 15 IA6: See docs/week15_ia6/test_strategy.docx, trust_boundaries.docx, hardening_report.docx, and Week15_IA6_Evidence_Pack.docx.
- Week 15 API collection: backend/postman/week15_ia6_collection.json

Built for PFEBSIT 002 - Integrative Programming and Technologies 2
