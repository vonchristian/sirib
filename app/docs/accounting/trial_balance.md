Trial Balance Module (Cooperative Core Banking Platform)
1. Overview

The Trial Balance module is a core accounting report in the cooperative banking system that provides a snapshot of all general ledger account balances at a specific point in time, ensuring that:

Total Debits = Total Credits

It acts as a financial integrity checkpoint before financial statements (Balance Sheet, Income Statement) are generated.

This module is part of the Accounting Domain and operates strictly on top of the existing ledger system:

Ledger
Account
Entry
EntryLines
2. Problem Statement

Cooperative banks need a reliable way to:

Verify correctness of posted journal entries
Detect unbalanced or corrupted ledger states
Support audit readiness (internal + external auditors)
Prepare financial statements from verified balances

Currently, the system lacks a structured, auditable, time-bound aggregation layer over ledger entries.

3. Goals
Primary Goal

Provide a verifiable Trial Balance report that confirms ledger integrity at any given date.

Secondary Goals
Support audit workflows
Enable month-end/year-end closing
Provide drill-down into accounts and entries
Serve as a foundation for financial statements
4. Non-Goals
Not responsible for correcting ledger errors (only detection/reporting)
Not a replacement for General Ledger
Not handling tax computation or regulatory reporting
Not performing reconciliation with external bank statements (separate module)
5. Core Concept

The Trial Balance is derived from:

EntryLines → grouped by Account → summed by debit/credit direction → as-of date filter

Each account shows:

Total Debits
Total Credits
Net Balance (optional display depending on configuration)
6. Domain Design (Rails 8)
Existing Models (REUSED)
Account
Ledger
Entry
EntryLine
7. New Domain Objects
7.1 TrialBalanceReport (NOT persisted OR optionally cached)

Represents a generated snapshot.

TrialBalanceReport
- as_of_date: date
- ledger_id: bigint (optional scope)
- status: enum (draft, finalized)
- total_debits: decimal
- total_credits: decimal
- balanced: boolean
7.2 TrialBalanceLine (virtual or persisted optional)
TrialBalanceLine
- account_id
- account_name
- debit_total
- credit_total
- net_balance
8. Core Business Logic
8.1 Computation Rules

For a given as_of_date:

Fetch all EntryLines where:

entry.posted_at <= as_of_date
entry.status = posted
Group by account_id
Aggregate:
debit_sum = SUM(debit_amount)
credit_sum = SUM(credit_amount)

Compute:

net = debit_sum - credit_sum

Validate:

total_debits == total_credits
=> balanced = true/false
9. Accounting Rules
9.1 Double Entry Constraint

Each Entry must always satisfy:

SUM(debit_lines) == SUM(credit_lines)

Trial Balance is a secondary validation layer, not primary enforcement.

11. UI Requirements (Admin Accounting Module)
11.1 Trial Balance Page

Features:

Date picker (as-of date)
Ledger filter (optional)
Table view:
Account Name
Debit
Credit
Net Balance
Summary footer:
Total Debits
Total Credits
Balanced status indicator (green/red)
11.2 Drill-down

Clicking an account:

Shows underlying EntryLines
Shows related Entries
Audit trail view
12. Edge Cases
12.1 Unbalanced Entries Exist

System should still compute trial balance but flag:

WARNING: Ledger integrity issue detected
12.2 Large Data Sets

Must support:

Pagination or server-side aggregation
Indexed queries on:
entry.posted_at
entry_lines.account_id
12.3 Backdated Entries

Entries posted after cutoff but with earlier effective date must NOT be included unless explicitly defined by accounting policy.

13. Performance Requirements
Generate trial balance for up to:
1M entry lines
< 2 seconds response time (target)
Use database aggregation (GROUP BY account_id)
Avoid Ruby-level iteration over entry lines
14. Security & Access Control

Only roles:

Accountant
Auditor
Admin

Can access:

Trial Balance report
Drill-down entry data
15. Audit Requirements

Every generated trial balance must be:

Timestamped
Reproducible
Linked to dataset version (entries snapshot logic)

Optional:

Store hash of computed results for audit integrity
16. Future Enhancements
Adjusted Trial Balance (with adjusting entries)
Comparative Trial Balance (month-over-month)
Branch-level Trial Balance
Consolidated Cooperative Group Trial Balance
Export to Excel / PDF
AI anomaly detection (unexpected account shifts)
17. Acceptance Criteria

System is considered complete when:

 Trial balance always balances when ledger is correct
 Detects imbalance when entries are broken
 Supports as-of-date filtering
 Aggregation is performant on large datasets
 Drill-down works per account
 Accessible via API and UI
 Secure by role-based access
18. End Goal for OpenCode

Implement a module that:

“Given a ledger system composed of Accounts, Entries, and EntryLines, produce a performant, auditable Trial Balance report that guarantees debit-credit validation at any point in time and supports drill-down inspection for accounting verification.”