# Week 13 - SA7 Automation Case: Classroom Issue Reporting System

## 1. Workflow boundary
- **Users:** students and faculty report; coordinator decides assignment and reviews failures; facilities staff repair.
- **Trigger 1 (event):** a report is submitted -> validate, route (category, priority, team), check duplicates, store, audit.
- **Trigger 2 (schedule):** every 15 min -> escalate issues still `reported`/`categorized` after 24 h.
- **Human points:** assigning, repairing, verifying, closing, and every item in the failure queue.
- **Trusted input:** only server-validated fields. Controlled fictional data only.
- **Non-goals (this week):** real authentication (Week 14), notifications, file uploads, mobile packaging.

## 2. Decision record - how to run the escalation job
| | |
|---|---|
| Context | Unassigned issues must not sit forgotten. One small API instance. |
| Decision | In-process `setInterval` job plus a manual "run now" endpoint. |
| Alternatives | OS cron / Task Scheduler (extra setup, separate logs); MySQL EVENT (logic hidden in the database); message queue (too heavy). |
| Consequences | Job stops if the server stops and catches up on the next tick (rule is time-based and idempotent). A second API instance would run it twice (harmless, but wasteful); needs a lock later. |
| Review when | More than one API instance, or the job becomes slow. |

## 3. Retry and recovery policy
- Transient codes (ECONNRESET, ETIMEDOUT, ECONNREFUSED, deadlock...) -> up to 3 attempts, delay 200 ms then 400 ms.
- Permanent errors -> no retry.
- After permanent failure or exhausted retries -> row in `automation_failures`, shown in the Flutter "Automation review" screen; a human marks it handled.
- Only operations safe to repeat are retried (duplicate check, escalation scan/update). The issue INSERT is not retried.
- If the duplicate check fails completely the report is still accepted (no lost reports) and the failure is queued.
- Logs and screens show error codes only, never SQL, messages, or free text.

## 4. API contract (JSON)
| Method and path | Who | Result |
|---|---|---|
| POST /api/issues | any | 201 issue (with `routedTeam`), 200 `{duplicate:true,...}`, 400 details, 503 |
| GET /api/issues?status= | any | 200 list, 400, 503 |
| GET /api/automation/failures?status=open | coordinator, facilitiesStaff | 200 list, 401, 403 |
| POST /api/automation/failures/:id/resolve | same | 200, 404, 403 |
| POST /api/automation/escalation/run | same | 200 `{ok,candidates,escalated}`, 409 if already running |
| GET /api/automation/status | same | last scheduler run |
Prototype note: staff identity is the `x-user-id` header checked against the database. It can be forged and is replaced by signed tokens in Week 14.

## 5. Flutter Web screen flow
Login -> Home (role based) -> Report an issue / View issues / Automation review.
States covered: validation, loading, success (shows routing result), duplicate, empty, network error (with retry), server error, not authorized.

## 6. Evidence to capture (put in your portfolio)
1. `npm test` output (8 passing) and `flutter test` output.
2. `npm run demo` output: Scenario 1 = recovered transient failure; Scenario 2 = permanent failure routed to a human.
3. Live version: stop MySQL Server, submit a report, restart it, show `automation_failures` rows in Workbench and in the Automation review screen.
4. Screenshots: report success, duplicate notice, empty list, network error, escalated chip, queue, "not authorized" as student. Resize the Chrome window for responsive evidence.
5. To show escalation: in Workbench run `UPDATE issues SET created_at = NOW() - INTERVAL 30 HOUR WHERE id = <id>;` then press "Run escalation check now".
6. Structured log lines from the API console (one JSON object per line).

## 7. Maintainability note
Small modules with one job each (`routing`, `duplicates`, `retry`, `escalation`, `scheduler`, `events`, `logger`); every setting comes from `.env`; routing rules are a data table; the Flutter API client maps every failure to a typed, user-safe exception. Known limits: keyword routing misses unusual wording (falls back to coordinator), in-process scheduler, header-based identity until Week 14.
