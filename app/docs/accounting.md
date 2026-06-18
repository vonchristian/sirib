# Product Manager Prompt: Accounting Operations Module (Core Banking System for Cooperatives)

## Role

You are an expert Product Manager specializing in **Core Banking Systems**, **Banking Accounting Architecture**, and **Financial Control Systems**.

Your task is to design a **production-grade Accounting Operations Module** that serves as the **financial truth layer** of a cooperative core banking system.

This is not bookkeeping UI.

This is the **system of record for all financial truth**.

---

# Business Context

The cooperative operates multiple financial domains:

* Loans (assets)
* Savings (liabilities)
* Time Deposits (liabilities)
* Share Capital (equity)
* Treasury Operations (cash movement layer)
* Expenses & Income (P&L)

All of these systems generate financial events.

The Accounting Module is responsible for:

> Converting every financial event into a correct, immutable, double-entry ledger.

---

# Core Design Principle

> “If it is not in the General Ledger, it did not happen.”

Accounting is:

* Immutable
* Auditable
* Always balanced
* System-generated (never manually adjusted in production)

---

# Feature 1 — General Ledger (GL) Engine

## Structure

* Chart of Accounts (CoA)
* Account Types:

  * Assets
  * Liabilities
  * Equity
  * Income
  * Expenses

---

## Rules

* Every transaction must balance:

  * Debit = Credit
* No orphan entries allowed
* No unclassified postings
* No manual GL overrides after posting

---

# Feature 2 — Journal Entry Engine

## Components

Each journal entry includes:

* Entry ID
* Date
* Reference (Loan, Savings, TD, Share, Treasury)
* Description
* Lines (Debits & Credits)
* Branch
* Currency

---

## Example

Loan Disbursement:

```text id="je_loan_001"
Debit: Loans Receivable
Credit: Cash on Hand
```

Savings Deposit:

```text id="je_sav_001"
Debit: Cash on Hand
Credit: Savings Liability
```

Share Capital Purchase:

```text id="je_share_001"
Debit: Cash on Hand
Credit: Share Capital Equity
```

---

# Feature 3 — Subledger System

Accounting must maintain subledgers for:

* Loans (per member, per loan)
* Savings (per account)
* Time Deposits (per placement)
* Share Capital (per member equity account)
* Treasury Cash (per branch/teller)

---

## Rule

Subledger totals MUST always reconcile with GL balances.

---

# Feature 4 — Accounting Events Engine

All systems emit events:

* LoanDisbursed
* LoanRepaid
* SavingsDeposited
* SavingsWithdrawn
* TDPlaced
* TDMatured
* SharePurchased
* CashReceived
* CashDisbursed

Each event produces:

1. Journal Entry
2. Ledger Update
3. Audit Log Entry

---

# Feature 5 — Posting Engine

## Lifecycle

1. Receive Event
2. Validate Accounting Rules
3. Generate Journal Entry
4. Balance Check (Debit = Credit)
5. Post to GL
6. Lock Entry (Immutable)
7. Emit Posted Event

---

## Rules

* No partial postings
* No edits after posting
* Only reversal entries allowed

---

# Feature 6 — Reversal Engine

Instead of edits:

* System generates reversing journal entry
* Original entry remains intact

Example:

```text id="rev_001"
Reverse Loan Disbursement

Debit: Cash on Hand
Credit: Loans Receivable
```

---

# Feature 7 — Trial Balance Engine

System must generate:

* Trial Balance (daily/monthly)
* Balance Sheet
* Income Statement
* Cash Flow Statement

---

## Rule

Trial Balance must always balance:

> Total Debits = Total Credits

---

# Feature 8 — Financial Statements Engine

## Reports

* Balance Sheet
* Income Statement
* Statement of Changes in Equity
* Cash Flow Statement

---

## Requirements

* Real-time or end-of-period generation
* Fully traceable to journal entries
* Drill-down capability

---

# Feature 9 — Period Closing Engine

## Processes

* Daily closing
* Monthly closing
* Year-end closing

---

## Rules

* No posting to closed periods
* Adjustments require new entries
* Closing entries must be auditable

---

# Feature 10 — Account Hierarchy (Chart of Accounts)

## Example Structure

```text id="coa_001"
1000 Assets
  1100 Cash on Hand
  1200 Loans Receivable

2000 Liabilities
  2100 Savings Deposits
  2200 Time Deposits

3000 Equity
  3100 Share Capital

4000 Income
  4100 Interest Income
  4200 Fees Income

5000 Expenses
  5100 Operating Expenses
```

---

## Rules

* Accounts must not be deleted if used
* Only inactive status allowed
* Hierarchy must be enforced

---

# Feature 11 — Multi-Branch Accounting

Each branch must have:

* Separate subledger views
* Consolidated GL view
* Inter-branch elimination entries

---

# Feature 12 — Audit Trail (Mandatory)

Every accounting action must log:

* Actor
* System source
* Timestamp
* Branch
* IP address
* Before/After state
* Journal reference
* Event source

---

## Rule

Accounting records are:

> Immutable by design

No edits. No deletion. Only reversals.

---

# Feature 13 — Validation Rules Engine

System must enforce:

* Balanced journal entries
* Valid account mapping
* No postings to inactive accounts
* No negative balances (unless allowed by product rules)
* Period validation (open/closed)
* Currency consistency

---

# Feature 14 — Integration Layer

Accounting module integrates with:

* Treasury Operations
* Loan System
* Savings System
* Time Deposit System
* Share Capital System

All integrations must be event-driven.

---

# Feature 15 — Permissions Model

## Accountant

* View journals
* Generate reports
* Cannot edit postings

## Auditor

* Read-only full access
* Drill-down capability

## Manager

* View reports
* Approve adjustments

## System Admin

* Configure CoA
* Manage accounting rules

---

# Feature 16 — UX Requirements

Accounting UI must be:

* Minimal
* Spreadsheet-like clarity
* Audit-first design
* Drill-down capable
* Fast search for journal entries
* No unnecessary UI decoration
* Built for accountants, not general users

---

# Event-Driven Architecture

Every financial event triggers:

* JournalEntryCreated
* JournalEntryPosted
* LedgerUpdated
* StatementUpdated
* AuditLogged

---

# Future Enhancements

Design for:

* IFRS 9 Expected Credit Loss (ECL)
* Automated provisioning
* Real-time financial dashboards
* AI anomaly detection in postings
* Regulatory reporting automation
* Tax reporting engine
* Multi-currency accounting
* Consolidated group accounting

---

# Expected Deliverables

Generate:

1. User Stories
2. Business Rules
3. Acceptance Criteria
4. Validation Rules
5. Domain Model
6. Database Schema
7. ERD
8. Rails Models
9. Service Objects
10. State Machines
11. Accounting Posting Engine Design
12. Journal Entry Lifecycle
13. Subledger Architecture
14. Chart of Accounts Design
15. API Endpoints
16. Hotwire UI Wireframes
17. Screen Layouts
18. Financial Reports Design
19. Audit Logging Strategy
20. Authorization Matrix
21. Period Closing Strategy
22. Event-Driven Architecture
23. Future Extension Strategy

---

# Technical Constraints

Must be designed for:

* Ruby on Rails 8
* Hotwire / Turbo / Stimulus
* PostgreSQL
* Solid Queue
* Domain-Driven Design (DDD)
* Event-driven architecture
* Double-entry accounting
* Strict immutability
* Banking-grade auditability
* High reliability systems

---

# Core Principle

> Accounting is the final source of truth.

If it is not in the ledger, it does not exist.
