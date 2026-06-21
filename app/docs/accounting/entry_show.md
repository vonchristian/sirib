Journal Entry Show Page (Accounting + Audit View Only)
1. Overview

The Journal Entry Show Page is a read-only, audit-grade view of a posted Journal Entry.

It is designed for:

Accountants → verification of correctness
Auditors → traceability and compliance checks
Finance Managers → review and explanation of entries

This page is NOT for editing, posting, or creating entries.

2. Goals
Primary Goals
Display full journal entry details clearly and accurately
Show debit/credit breakdown with total validation
Provide traceability (source + audit history)
Make financial impact understandable at a glance
Non-Goals
No creation of journal entries
No editing or posting actions
No voucher/template logic
No business rule execution
3. Page Layout Specification
3.1 Header Section

Must display:

Journal Entry Number (e.g., JE-2026-000123)
Entry Date (accounting date)
Posted At timestamp
Created By user
Source Module (e.g., Voucher, Loan, Cash, System Batch)
External Reference (optional)
3.2 Financial Summary Panel

This is the most important validation block.

Must show:

Total Debits
Total Credits
Difference (should always be 0)
Balance Status:
✅ Balanced
❌ Unbalanced (critical alert)

Rules:

If unbalanced ever appears, UI must highlight in red
3.3 Journal Lines Table (Core Section)

Each line shows:

| Account Code | Account Name | Debit | Credit | Memo |

Rules:

Only one of Debit or Credit is allowed per line
Account name must be snapshot (historical, not live lookup)
Lines must be ordered by sequence
3.4 Account Breakdown (Drilldown View)

For each line:

Account hierarchy (e.g., Assets → Cash → Cash on Hand)
Account type (Asset / Liability / Income / Expense / Equity)
Normal balance side (Debit or Credit)
Line impact explanation (simple text)
3.5 Source Reference Section

Shows origin of the entry:

Source Type (Voucher, Loan, Manual, System)
Source ID (clickable link if available)
Reference Notes (if any)

Purpose:

Let auditors trace where the entry came from.

3.6 Audit Trail Section

Immutable event log:

Each event includes:

Event type (Created, Posted, Reversed)
Timestamp
Actor (User/System)
Metadata (expandable JSON or structured view)

Order: newest → oldest

3.7 Reversal Section (if applicable)

If entry is reversed:

Reversal Journal Entry ID
Reversal Date
Reason for reversal
Link back to original entry
4. Data Contract (Read-only API)
GET /journal_entries/:id
{
  "id": 1,
  "entry_number": "JE-2026-000123",
  "entry_date": "2026-06-20",
  "posted_at": "2026-06-20T10:00:00Z",
  "created_by": "Juan Dela Cruz",
  "source": {
    "type": "Voucher",
    "id": 55
  },
  "summary": {
    "total_debit": 10000,
    "total_credit": 10000,
    "difference": 0,
    "balanced": true
  },
  "lines": [
    {
      "account_code": "1000",
      "account_name": "Cash",
      "debit": 10000,
      "credit": 0,
      "memo": "Loan proceeds"
    }
  ],
  "audit_trail": [
    {
      "event": "posted",
      "timestamp": "2026-06-20T10:00:00Z",
      "actor": "system"
    }
  ]
}
5. UI Requirements
Must Have
Read-only layout
Sticky summary panel (totals always visible)
Clear debit/credit separation
Highlight balance status prominently
Expandable audit trail section
Visual Rules
Debits = left aligned / green tint (optional)
Credits = right aligned / blue tint (optional)
Errors/unbalanced = red banner
6. Validation Rules (Display Only)

The page must:

Always recompute totals from lines
Never trust stored totals alone
Show mismatch if backend data is inconsistent
7. Permissions
Role	Access
Accountant	View
Auditor	View + export
Manager	View
Others	Denied
8. Performance Requirements
Load time < 300ms (typical entry)
Supports up to 500 lines
Audit trail lazy-loaded if large
9. Unit Tests (RSpec)
9.1 Summary calculation correctness
RSpec.describe "JournalEntry show data" do
  it "correctly computes debit and credit totals" do
    entry = create(:journal_entry)

    create(:journal_entry_line, journal_entry: entry, debit_amount: 100, credit_amount: 0)
    create(:journal_entry_line, journal_entry: entry, debit_amount: 0, credit_amount: 100)

    expect(entry.total_debits).to eq(100)
    expect(entry.total_credits).to eq(100)
  end
end
9.2 Balance state detection
it "detects balanced entry correctly" do
  entry = build(:journal_entry)

  allow(entry).to receive(:total_debits).and_return(100)
  allow(entry).to receive(:total_credits).and_return(100)

  expect(entry.balanced?).to eq(true)
end
9.3 Line integrity
it "ensures each line has either debit or credit only" do
  line = build(:journal_entry_line, debit_amount: 100, credit_amount: 0)

  expect(line.debit_amount > 0 && line.credit_amount == 0).to eq(true)
end
10. E2E Tests (Playwright)
10.1 Page loads correctly
test("journal entry show page loads correctly", async ({ page }) => {
  await page.goto("/journal_entries/1");

  await expect(page.locator("[data-testid=entry-number]")).toBeVisible();
});
10.2 Totals display correctly
test("shows correct debit and credit totals", async ({ page }) => {
  await page.goto("/journal_entries/1");

  await expect(page.locator("[data-testid=total-debit]")).toBeVisible();
  await expect(page.locator("[data-testid=total-credit]")).toBeVisible();
});
10.3 Balance indicator
test("shows balanced indicator", async ({ page }) => {
  await page.goto("/journal_entries/1");

  await expect(page.locator("[data-testid=balance-status]"))
    .toContainText("Balanced");
});
10.4 Audit trail visibility
test("audit trail is visible", async ({ page }) => {
  await page.goto("/journal_entries/1");

  await expect(page.locator("text=Audit Trail")).toBeVisible();
});
11. Acceptance Criteria
 Entry header displays correct metadata
 Totals correctly computed from lines
 Balance status always accurate
 Line items displayed correctly
 Audit trail visible and ordered
 Source reference shown
 Page is strictly read-only
 Works up to 500 lines without degradation
12. Final Definition

The Journal Entry Show Page is a deterministic, read-only, audit-grade visualization of a single immutable accounting record, fully reconstructed from stored ledger lines.