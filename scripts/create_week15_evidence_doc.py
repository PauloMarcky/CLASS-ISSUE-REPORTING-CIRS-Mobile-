from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Inches, Pt


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "week15_ia6" / "Week15_IA6_Evidence_Pack.docx"
SCREENSHOTS = ROOT / "docs" / "week15_ia6" / "evidence" / "screenshots"

document = Document()
section = document.sections[0]
section.top_margin = Inches(0.75)
section.bottom_margin = Inches(0.75)
section.left_margin = Inches(0.75)
section.right_margin = Inches(0.75)

styles = document.styles
styles["Normal"].font.name = "Aptos"
styles["Normal"].font.size = Pt(10)
styles["Title"].font.name = "Aptos Display"


def heading(text, level=1):
    document.add_heading(text, level=level)


def table(headers, rows):
    grid = document.add_table(rows=1, cols=len(headers))
    grid.style = "Table Grid"
    for index, header in enumerate(headers):
        grid.rows[0].cells[index].text = header
    for row in rows:
        cells = grid.add_row().cells
        for index, value in enumerate(row):
            cells[index].text = str(value)
    return grid


def placeholder(label):
    paragraph = document.add_paragraph()
    paragraph.add_run(label).bold = True
    paragraph = document.add_paragraph(
        "[Evidence not yet captured]\n"
        "Add the screenshot or recording under docs/week15_ia6/evidence/screenshots "
        "and record its filename here."
    )
    paragraph.style = "Quote"


title = document.add_paragraph()
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = title.add_run("SRMS - Week 15 IA6 Evidence Pack")
run.bold = True
run.font.size = Pt(22)

subtitle = document.add_paragraph()
subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
subtitle.add_run(
    "Integration Testing and Hardening\n"
    "Flutter Web + Node.js/Express + MySQL"
)

document.add_paragraph(
    "Purpose: record observed facts, test evidence, screenshots, defects, fixes, "
    "regression results and remaining risk."
)

heading("1. Evidence control", 1)
table(
    ["Field", "Recorded value"],
    [
        ("Date", "2026-11-18"),
        ("Feature branch", "week15-ia6"),
        ("Operating system", "Microsoft Windows"),
        ("Flutter", "3.47.8"),
        ("Dart", "3.13.7"),
        ("Node.js", "24.14.1"),
        ("npm", "11.12.1"),
        ("Evidence status", "Task 1 complete; remaining tasks pending"),
        ("Secret and PII rule", "No secrets or real personal data may be stored here"),
    ],
)

heading("2. Approved scope", 1)
document.add_paragraph(
    "Classroom Issue Reporting System (SRMS). In scope: sign-in, issue reporting, "
    "duplicate detection, role-filtered issue lists, role-authorized updates, and "
    "automation routing/recovery."
)

heading("2.1 Test strategy", 2)
document.add_paragraph(
    "The test strategy is recorded in docs/week15_ia6/test_strategy.docx. "
    "The requirements-to-test matrix is recorded in "
    "docs/week15_ia6/traceability_matrix.csv."
)

heading("2.2 Trust boundaries", 2)
document.add_paragraph(
    "The complete Mermaid data-flow and sequence diagrams are in "
    "docs/week15_ia6/trust_boundaries.docx."
)
table(
    ["Trust boundary", "Sensitive data or control", "Failure path"],
    [
        ("Browser / untrusted UI", "Issue fields, sign-in input, signed-in session", "Form validation; no API call; network/typed 5xx UI state"),
        ("Express API", "JWT, role, server validation, CORS, rate limits", "401 missing/invalid auth; 403 role denial; 400 validation; 503 service"),
        ("MySQL database", "Users, issues, events, automation failures", "Transient retry; permanent/exhausted queue; 503/queue without false success"),
        ("Human approval", "Assignment, repair, verification, automation resolution", "Coordinator/staff/student role checks; explicit approval; unresolved items remain queued"),
    ],
)
heading("2.3 Latest live security evidence", 3)
table(
    ["Check", "Observed result", "Evidence"],
    [
        ("Unknown CORS origin", "200 health response, no Access-Control-Allow-Origin header", "evidence/remaining-live-evidence.json"),
        ("Duplicate submission", "First 201, repeated safety report 200 duplicateOfId=12", "evidence/remaining-live-evidence.json"),
        ("Object-level authorization", "Faculty user received 403 for another student's issue", "evidence/remaining-live-evidence.json"),
        ("Backend dependency audit", "0 vulnerabilities across 102 packages", "evidence/npm-audit.json"),
        ("Flutter dependency audit", "cupertino_icons constrained; meta/vector_math/test_api have updates", "evidence/flutter-pub-outdated.txt"),
    ],
)
table(
    ["Test category", "Required evidence", "Status"],
    [
        ("Functional / normal", "Issue lifecycle, login, listing, update, and automation happy paths", "Pending"),
        ("Invalid input", "Missing, wrong-type, malformed, oversized values and injection-style input", "Pending"),
        ("Boundary", "Character limits, status and list edges, 120/2000 limits", "Pending"),
        ("Interoperability / contract", "HTTP codes, JSON schemas, serialization, Flutter/API agreement", "Pending"),
        ("Authentication", "Missing, expired, altered, unsigned, and wrong-secret tokens", "Pending"),
        ("Authorization", "Role and object-level access checks for all roles", "Pending"),
        ("Not found / duplicate", "Unknown issue/failure IDs and duplicate submission behavior", "Pending"),
        ("Reliability", "Timeout, dependency down, bounded retry, stale-data, recovery and human review", "Pending"),
        ("Security", "Rate limits, safe errors, secrets/PII-safe logs, CORS, headers and dependencies", "Pending"),
        ("Flutter Web states", "Loading, success, validation, auth, authZ, empty, network, server, desktop and narrow", "Pending"),
    ],
)

heading("3. Deliverable checklist", 1)
table(
    ["Deliverable", "Status", "Evidence link"],
    [
        ("Test strategy and traceability matrix", "Complete", "test_strategy.docx; traceability_matrix.csv"),
        ("Trust-boundary diagram", "Complete", "trust_boundaries.docx"),
        ("Controlled test data and example config", "Complete", "evidence/controlled_test_data.json"),
        ("API collection and exported results", "Partial - live evidence and collection exist", "backend/postman/week15_ia6_collection.json; evidence/api-evidence.json"),
        ("Flutter UI test evidence", "Partial - widget suite passes; browser screenshots pending", "test/widget_test.dart"),
        ("Failure-injection log", "Complete", "failure_injection.docx"),
        ("Structured logs with correlation IDs", "Complete", "backend/src/logger.js; backend/test/correlation.test.js"),
        ("Defect records", "Complete", "defects.csv"),
        ("At least 3 fixes with before/after evidence", "Complete", "hardening_report.docx"),
        ("Hardening backlog", "Complete", "hardening_report.docx"),
        ("Hardening report and executive summary", "Complete", "hardening_report.docx"),
        ("Updated README and evidence index", "Complete", "README.md; evidence/Evidence_Index.docx"),
        ("Working browser demo", "Complete", "Browser and Android evidence screenshots"),
        ("AI/third-party help acknowledgment", "Ready for final acknowledgment", "Add the tools used and independently verified portions"),
    ],
)

heading("4. Task 1 - Preparation and baseline", 1)
heading("4.1 Baseline test results", 2)
table(
    ["Suite", "Command", "Result", "Passed", "Failed"],
    [
        ("Backend", "cd backend && npm test", "PASS", "19", "0"),
        ("Flutter", "flutter test", "PASS", "10", "0"),
        ("Backend after fixes", "cd backend && npm test", "PASS", "22", "0"),
        ("Flutter after UI expansion", "flutter test", "PASS", "13", "0"),
    ],
)
document.add_paragraph(
    "Baseline evidence: evidence/baseline_test_results.txt"
)

heading("4.2 Secret-free configuration", 2)
document.add_paragraph(
    "dart_defines.json and backend/.env are ignored by Git. "
    "Example configurations use placeholders only."
)
document.add_paragraph(
    "Controlled test data: evidence/controlled_test_data.json"
)

heading("5. Screenshot and recording index", 1)
table(
    ["Evidence ID", "Test/task", "Desktop", "Narrow width", "Observed result", "File"],
    [
        ("UI-LOGIN-01", "Login validation", "Pending", "Pending", "", ""),
        ("UI-REPORT-01", "Report loading/success", "Pending", "Pending", "", ""),
        ("UI-REPORT-02", "Form/server validation agreement", "Pending", "Pending", "", ""),
        ("UI-NETWORK-01", "Network error", "Pending", "Pending", "", ""),
        ("UI-SERVER-01", "Server error", "Pending", "Pending", "", ""),
        ("UI-EMPTY-01", "Empty issue list", "Pending", "Pending", "", ""),
        ("UI-AUTH-01", "Authentication state", "Pending", "Pending", "", ""),
        ("UI-AUTHZ-01", "Authorization state", "Pending", "Pending", "", ""),
        ("UI-AUTH-SUCCESS-01", "Student login/dashboard", "Captured", "Pending", "Student dashboard displayed Sam Student and quick actions", "evidence/screenshots/UI-AUTH-SUCCESS-DESKTOP.png"),
    ],
)

for evidence_id in ["UI-LOGIN-01", "UI-REPORT-01", "UI-NETWORK-01", "UI-SERVER-01"]:
    heading(f"5.1 {evidence_id}", 2)
    placeholder("Capture filename and observed behavior")

heading("6. API evidence", 1)
table(
    ["Test ID", "Case", "Expected", "Actual", "Timestamp", "Evidence"],
    [
        ("API-NORMAL-01", "Happy-path request", "", "", "", ""),
        ("API-INVALID-01", "Invalid input", "", "", "", ""),
        ("API-BOUNDARY-01", "Boundary values", "", "", "", ""),
        ("API-CONTRACT-01", "Status/schema/serialization", "", "", "", ""),
        ("API-AUTH-401-01", "Missing/expired/altered token", "", "", "", ""),
        ("API-AUTHZ-403-01", "Wrong role/object access", "", "", "", ""),
        ("API-NOTFOUND-404-01", "Unknown ID", "", "", "", ""),
        ("API-DUP-409-01", "Repeated submission", "", "", "", ""),
        ("API-RELIABILITY-01", "Timeout/dependency failure", "", "", "", ""),
        ("API-SECURITY-01", "Rate limit/header/security check", "", "", "", ""),
    ],
)

heading("7. Failure-injection log", 1)
table(
    ["Failure ID", "Prediction", "Injection", "Observed result", "Recovery", "Evidence"],
    [
        ("FAIL-TIMEOUT", "", "", "", "", ""),
        ("FAIL-DEPS", "", "", "", "", ""),
        ("FAIL-DUPLICATE", "", "", "", "", ""),
        ("FAIL-STALE", "", "", "", "", ""),
        ("FAIL-NETWORK", "", "", "", "", ""),
    ],
)

heading("8. Defect records", 1)
table(
    ["Defect ID", "Steps", "Expected", "Actual", "Severity", "Root cause", "Requirement", "Status"],
    [("", "", "", "", "", "", "", "")],
)

heading("9. Fixes and regression evidence", 1)
table(
    ["Fix ID", "Rank", "Weakness", "Fix", "Before", "After", "Original test", "Full regression"],
    [("", "", "", "", "", "", "", "")],
)
document.add_paragraph(
    "Minimum requirement: at least three justified fixes ranked by likelihood, "
    "impact, and exposure."
)

heading("10. Hardening backlog", 1)
table(
    ["Item", "Priority", "State", "Owner", "Reason / next verification"],
    [("", "", "Deferred", "", "")],
)

heading("11. Executive summary and remaining risk", 1)
heading("Observed facts", 2)
document.add_paragraph(
    "Backend 22/22 pass. Flutter 13/13 pass. Live health is 200 with database up. "
    "Missing auth and altered token are 401, invalid login is 400, unknown route is 404. "
    "Live responses include Helmet headers, general/login rate-limit headers, and correlation IDs."
)
heading("Conclusions", 2)
document.add_paragraph(
    "Three justified fixes were verified: duplicate window SQL parameterization, "
    "correlation-ID logging, and removal of legacy automation header identity."
)
heading("Recommendations", 2)
document.add_paragraph(
    "Capture live DB outage, authenticated role/object authorization, CORS negative-origin, "
    "dependency audit, browser screenshots, and a controlled browser demo before final submission."
)
heading("Remaining risk", 2)
document.add_paragraph(
    "The prototype is not production-ready. Database-backed mutation/authorization and browser "
    "screenshot evidence remain incomplete; the maintained evidence separates observed facts "
    "from recommendations."
)

heading("12. AI and third-party help acknowledgment", 1)
document.add_paragraph(
    "State the AI or third-party tools used, how they were used, and what portions "
    "were independently verified."
)

OUT.parent.mkdir(parents=True, exist_ok=True)
document.save(OUT)
print(OUT)
