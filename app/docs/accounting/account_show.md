Account Show Page (Chart of Accounts → Account Detail)

System: Cooperative Core Banking Platform (Rails 8)
Audience: Accountants, Auditors, Finance Managers
Scope: Account Show Page only (no dashboard, no reporting module expansion)

1. Problem Statement

When accountants click an account from the Chart of Accounts, they need a single source of truth page that:

Shows the account’s full financial state
Lets them trace all postings (auditability)
Helps validate correctness (debits = credits integrity downstream)
Enables quick investigation of activity without navigating multiple screens

The current system lacks a focused account-level ledger view optimized for audit and reconciliation.

2. Goal

Build an Account Show Page that provides:

Complete account identity and structure
Transaction-level ledger visibility
Running balance visibility
Audit-friendly traceability to journal entries
Fast filtering for investigation
3. Non-Goals
No journal entry creation/editing
No approval workflows
No reporting dashboards (trial balance, P&L, etc.)
No posting logic changes
4. Entry Point

From Chart of Accounts index page:

/accounts/:id

Clicking an account opens this show page.

5. Core Data Requirements
Account Model (assumed existing)
id
code
name
type (Asset, Liability, Equity, Income, Expense)
parent_account_id (optional hierarchy)
normal_balance (debit/credit)
is_active
Ledger Data (required associations)

Must be able to retrieve:

JournalEntryLines (or EntryLines)
JournalEntry (parent)
Posted date
Debit amount
Credit amount
Running balance (computed or cached)
6. Page Layout
6.1 Header Section (Account Summary)

Displays:

Account Code + Name (primary title)
Account Type
Normal Balance (Debit/Credit)
Current Balance (computed)
Status (Active/Inactive)
Parent Account (if hierarchical)

Optional but useful:

Last posted date
Total debits (lifetime)
Total credits (lifetime)
6.2 Balance Snapshot Panel

A compact summary card:

Opening balance (period-based optional)
Total debits
Total credits
Net movement
Current balance

This is NOT a dashboard—only contextual snapshot for accountants.

6.3 Ledger Transactions Table (Core Section)

This is the most important part.

Columns:
Date (JournalEntry posted_at)
Journal Entry No / Reference
Description / Memo
Debit
Credit
Running Balance
Source (Voucher / Template origin if available)
Posted by (user)
Status indicator (if entries ever have state; otherwise omit)
Behavior:
Sorted by date ASC or DESC (user toggle)
Running balance recalculated per view or precomputed
Clicking row opens Journal Entry show page
6.4 Filters (High Priority for Accountants)

Must support:

Date Filters
From date
To date
Quick ranges:
Today
This month
Last month
Year-to-date
Entry Filters
Debit only
Credit only
Amount range (min/max)
Reference text search (journal entry number / memo)
Source Filters
Voucher type (if applicable)
Entry template source (if tracked)
6.5 Audit Trail Panel (Read-only)

For compliance clarity:

Created at / created by
Last updated at / updated by
Posting batch ID (if batch processing exists)
Link to background job / queue ID (optional integration with Solid Queue dashboard later)
6.6 Drilldown Behavior

Each ledger line must allow:

Click → Journal Entry Show Page
Show full double-entry context:
All debit lines
All credit lines
Balanced check confirmation
7. Business Rules
7.1 Data Integrity Constraint (existing system rule)
JournalEntry must always be balanced:
total debits == total credits

This page assumes:

No unbalanced entries exist in persisted state
7.2 Balance Calculation Rule
Running balance must follow account normal balance:
Asset/Expense → Debit increases balance
Liability/Equity/Income → Credit increases balance
8. Performance Requirements
Page load: < 300ms for accounts with ≤ 5,000 ledger lines
Pagination required beyond 100 rows (infinite scroll or paginated table)
Indexing required on:
account_id
posted_at
journal_entry_id
9. UX Requirements
Must be accountant-first: dense, not decorative
No unnecessary charts or marketing-style UI
Must support keyboard navigation in table
Row hover highlights for audit scanning
Sticky header for filters + account identity
10. API / Controller Design (Rails 8)
Controller
AccountsController#show
Data loading responsibilities:
@account
@ledger_lines
@summary
Optional service object:
Accounts::LedgerQueryService

Responsibilities:

Fetch filtered ledger lines
Compute running balance
Apply pagination
Apply date filters
11. Data Query Shape (Important)

Ledger line should be a unified object:

{
  date:,
  journal_entry_id:,
  entry_number:,
  memo:,
  debit:,
  credit:,
  running_balance:,
  posted_by:,
  source_type:
}
12. Edge Cases
Account with no transactions → show empty state with “No ledger activity”
Deleted journal entries (soft delete) → must still preserve audit trace or show “voided”
Very large accounts → pagination required
Future-dated entries → included but visually distinct (optional flag)
13. Security / Permissions

Roles:

Accountant → full read access
Auditor → full read access + export
Teller/Clerk → no access (or restricted based on org rules)

Must enforce:

Account-level authorization
Journal entry visibility rules
14. Testing Requirements
Unit Tests (RSpec)
Account balance computation correctness
Running balance calculation accuracy
Debit/Credit filtering logic
Date range filtering
Authorization rules
Service Tests
Accounts::LedgerQueryService:
correct ordering
correct pagination
correct filtering combinations
E2E Tests (Playwright)
Test Scenarios:
Navigate from Chart of Accounts → Account Show
Verify account header details render correctly
Verify ledger table loads and is sortable
Apply date filter → results update correctly
Click ledger row → navigates to Journal Entry show page
Verify running balance consistency across rows
Large dataset pagination works
15. Acceptance Criteria

Page is complete when:

 Account header displays correct metadata
 Ledger table shows all journal entry lines
 Running balance is accurate per row
 Filters work independently and combined
 Clicking a row opens journal entry show page
 Page performs within required limits
 E2E tests pass for navigation + filtering + drilldown
16. Future Extensions (NOT IN SCOPE)
Export to Excel / CSV
Account-level mini analytics
Drilldown to branch-level aggregation
Reconciliation assistant
AI anomaly detection