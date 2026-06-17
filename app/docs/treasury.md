# Product Manager Prompt: Unified Treasury Operations (Core Banking System for Cooperatives)

## Role

You are an expert Product Manager specializing in **Core Banking Systems**, **Treasury Operations**, and **Financial Control Architecture** for cooperatives.

You are designing a **Unified Treasury Operations Module** that acts as the central processing layer for all financial movements across:

* Loans
* Savings Accounts
* Time Deposits
* Share Capital

This is not a reporting tool.

This is the **real-time financial execution and control layer** of a core banking system.

---

# Business Context

In a cooperative banking system, all money movement ultimately flows through treasury.

Treasury is responsible for:

* Cash movement control
* Bank transfers
* Internal fund routing
* GL posting coordination
* Liquidity management
* End-of-day reconciliation
* Branch balancing

However, treasury does NOT operate in isolation.

It executes financial operations from:

## Member Banking Domains

* Loan Operations (disbursement, repayment, restructuring)
* Savings Operations (deposit, withdrawal, interest posting)
* Time Deposit Operations (placement, maturity, early withdrawal)
* Share Capital Operations (subscription, purchase, equity updates)

All of these are executed through treasury-controlled financial movements.

---

# Core Design Principle

> Treasury does not “record” money. Treasury “moves” money.

Every operation must:

* Move cash or ledger positions
* Generate double-entry accounting
* Update member balances
* Be fully auditable
* Be reversible (never editable)

---

# Feature 1 — Treasury Cash Movement Engine

All financial activity is translated into cash/ledger movements:

## Movement Types

* CASH_IN
* CASH_OUT
* INTERNAL_TRANSFER
* BANK_TRANSFER
* LEDGER_ADJUSTMENT

---

## Rules

* Every movement must originate from a business operation:

  * Loan disbursement
  * Savings deposit
  * TD placement
  * Share purchase
  * Expense payment

* No “free-form” treasury entries allowed

---

# Feature 2 — Loan Operations via Treasury

Treasury executes:

## Loan Disbursement

* Cash OUT or Bank OUT
* Loan Receivable increases

### Accounting

```text
Debit: Loans Receivable
Credit: Cash / Bank
```

---

## Loan Repayment (via Treasury)

* Cash IN or Bank IN
* Allocation engine distributes:

  1. Penalty
  2. Interest
  3. Principal

### Accounting

```text
Debit: Cash / Bank
Credit: Interest Income
Credit: Penalty Income
Credit: Loans Receivable
```

---

## Loan Restructuring (Treasury Impact)

* Adjust receivables
* Reclassify balances
* No cash movement unless refinancing occurs

---

# Feature 3 — Savings Operations via Treasury

## Deposit

* Cash IN increases
* Savings Liability increases

```text
Debit: Cash on Hand
Credit: Savings Liability
```

---

## Withdrawal

* Cash OUT decreases
* Savings Liability decreases

```text
Debit: Savings Liability
Credit: Cash on Hand
```

---

## Interest Posting

* Non-cash movement (ledger-only)

```text
Debit: Interest Expense
Credit: Savings Liability
```

---

# Feature 4 — Time Deposit Operations via Treasury

## Placement

* Cash IN
* Time Deposit Liability increases

```text
Debit: Cash on Hand
Credit: Time Deposit Liability
```

---

## Maturity

* Liability settled or rolled over
* Interest recognized

---

## Early Withdrawal

* Cash OUT
* Penalty calculation required

---

# Feature 5 — Share Capital Operations via Treasury

## Share Purchase

* Cash IN
* Equity increases

```text
Debit: Cash on Hand
Credit: Share Capital Equity
```

---

## Key Rules

* Must respect:

  * Minimum shares
  * Maximum shares
  * Share price
* Equity ledger is always updated in real-time

---

# Feature 6 — Cash Disbursements (Operational Treasury)

Used for:

* Expenses
* Loan releases
* Refunds
* Vendor payments

```text
Debit: Expense / Asset / Loans Receivable
Credit: Cash on Hand
```

---

# Feature 7 — Cash Receipts (Operational Treasury)

Used for:

* Loan payments
* Deposits
* Fees
* Income collection

```text
Debit: Cash on Hand
Credit: Income / Liability / Receivable
```

---

# Feature 8 — Bank Transfers Engine

Supports:

* Cash ↔ Bank
* Bank ↔ Bank
* Inter-branch transfers

Rules:

* Must always balance
* Must have settlement status:

  * Pending
  * Cleared
  * Failed

---

# Feature 9 — Cash Vault & Branch Liquidity

Treasury controls:

* Vault cash per branch
* Teller cash limits
* Cash replenishment
* Cash pooling between branches

Rules:

* Vault must always reconcile with GL Cash account
* No unexplained variances allowed

---

# Feature 10 — Petty Cash System

* Fixed petty cash fund per branch
* Expense liquidation required
* Replenishment requires approval

---

# Feature 11 — End-of-Day (EOD) Treasury Control

Critical system function.

## Steps:

1. Lock all cash movements
2. Aggregate all transactions
3. Compute teller balances
4. Compare system vs physical cash
5. Detect variances
6. Require supervisor approval
7. Post adjustment entries (if needed)
8. Generate EOD reports

---

## Outputs:

* Cash Position Report
* Teller Balancing Report
* Branch Summary
* Variance Report
* Exception Report

---

# Feature 12 — Cash Counting System

* Denomination-based counting
* Physical vs system reconciliation
* Variance tracking
* Supervisor approval required for mismatch

---

# Feature 13 — Income & Expense Recording

## Income

* Fees
* Interest income
* Penalties

## Expenses

* Salaries
* Utilities
* Rent
* Operations

All must:

* Flow through treasury
* Be posted to GL
* Be fully auditable

---

# Feature 14 — Treasury Ledger Engine

All operations map into:

## Accounting Model

* Assets (Cash, Loans Receivable)
* Liabilities (Savings, Time Deposits)
* Equity (Share Capital)
* Income (Fees, Interest, Penalties)
* Expenses (Operations)

---

# Feature 15 — Audit Trail (Mandatory)

Every treasury operation must store:

* Actor
* Branch
* Timestamp
* Device
* IP address
* Before state
* After state
* Approval chain
* Reference numbers

No edits allowed after posting.

Only reversals allowed.

---

# Feature 16 — Permissions Model

## Teller

* Cash operations
* Basic transactions

## Supervisor

* Approvals
* Variance handling

## Manager

* High-value approvals
* EOD review

## Accounting

* GL reconciliation

## Auditor

* Read-only full access

## Admin

* System configuration

---

# Feature 17 — UX Requirements

Treasury UI must be:

* Fast (teller-speed workflows)
* Minimal
* Financial-grade
* Keyboard-driven
* Strict validation
* Always show balances
* Always require confirmation before posting
* No decorative UI

---

# Event-Driven Architecture

Every treasury operation emits events:

* CashReceived
* CashDisbursed
* LoanDisbursed
* LoanRepaid
* SavingsDeposited
* TDPlaced
* SharePurchased
* EODClosed

Events trigger:

* GL posting
* Notifications
* Reporting
* Audit logs

---

# Future Enhancements

Design for:

* Real-time bank API integration
* Automated reconciliation
* AI anomaly detection
* Cash forecasting
* Fraud detection
* Multi-branch liquidity optimization
* Regulatory reporting engine
* IFRS compliance layer
* Fully automated EOD closing
* Digital receipts + QR payments

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
11. Treasury Workflow Engine
12. Accounting Engine Design
13. Ledger Posting Rules
14. API Endpoints
15. Hotwire UI Wireframes
16. Screen Layouts
17. Dashboard Design
18. Audit Logging Strategy
19. Authorization Matrix
20. Cash Flow Architecture
21. EOD Reconciliation Design
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
* Strict auditability
* High consistency financial systems

---

# Core Principle

> Treasury is the execution layer of truth.

If it does not pass through treasury, it does not exist in the system.
