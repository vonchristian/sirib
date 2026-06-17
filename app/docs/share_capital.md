# Product Manager Prompt: Share Capital Module for a Cooperative Core Banking System

## Role

You are an experienced Product Manager specializing in **Core Banking Systems** and **Cooperative Financial Management**.

Your task is to design a **production-ready Share Capital module** for a cooperative core banking application.

Think like a banking product manager—not a CRUD application developer.

The output should model real-world banking operations with strong accounting, auditability, and future regulatory compliance.

---

# Business Context

The application is a **Core Banking Platform** built specifically for **Cooperatives**.

Members become owners of the cooperative by purchasing **Share Capital**.

Unlike savings or deposits, Share Capital is part of the cooperative's **Equity**.

Every share purchase must produce proper accounting entries and update the member's ownership.

The system must support multiple Share Capital products.

Examples:

* Common Shares
* Preferred Shares
* Founder Shares
* Class A Shares
* Class B Shares

Each product may have different business rules.

---

# Objectives

Design:

* Business workflows
* UI/UX
* Database schema
* Domain model
* Accounting entries
* Service layer
* Validation rules
* Audit logging
* User permissions

Avoid generic CRUD. Design a banking-grade module.

---

# Feature 1 — Share Capital Product

Design the screen for creating a Share Capital Product.

## Basic Information

* Product Code
* Product Name
* Description
* Share Type

  * Common
  * Preferred
  * Other
* Status
* Effective Date

---

## Share Rules

* Price Per Share
* Minimum Required Shares
* Maximum Allowed Shares
* Minimum Initial Purchase
* Allow Fractional Shares (Yes/No)
* Redeemable (Yes/No)
* Dividend Eligible (Yes/No)
* Voting Rights (Yes/No)

---

## Accounting Configuration

When a Share Capital Product is created, automatically create the required Equity Ledger.

Example chart of accounts:

```text
1000 Equity
    1100 Share Capital
        1101 Common Shares
        1102 Preferred Shares
```

Users must not manually create these ledgers.

The system should provision them automatically.

---

## Validation Rules

Prevent:

* Negative share price
* Zero share price
* Minimum shares greater than maximum
* Duplicate product code
* Editing accounting mappings after transactions exist

---

# Feature 2 — Open Share Capital Account

When a member opens a Share Capital Account:

Automatically create:

* Equity Account
* Member Share Capital Account

No manual accounting setup should be required.

---

## Inputs

* Member
* Share Capital Product
* Opening Date
* Branch
* Remarks

---

## Display

Show:

* Shares Owned
* Paid-up Shares
* Remaining Shares Required
* Total Equity Value
* Current Share Price

---

# Feature 3 — Buy Shares

Create a transaction named:

**Buy Shares**

---

## Supported Payment Sources

Initially:

* Cash on Hand

Future support:

* Savings Account
* Loan Proceeds
* Payroll Deduction
* External Payment Gateway

---

## Workflow

User enters:

* Number of Shares

System automatically computes:

```text
Total Amount =
Number of Shares × Price Per Share
```

Display a confirmation summary before posting.

Example:

```text
Buying Shares

Shares: 25
Price per Share: ₱100
Total Amount: ₱2,500
```

---

## After Posting

Automatically:

* Increase Member Equity Account
* Increase Product Equity Ledger
* Record General Ledger Entries
* Record Audit Log
* Record Member Transaction History
* Update Share Ownership

Transactions become immutable after posting.

---

# Accounting Entries

Example Journal Entry

```text
Debit
Cash on Hand
₱2,500

Credit
Share Capital Equity
₱2,500
```

Future-proof the accounting engine to support:

* Multiple branches
* Multi-currency
* Reversals
* Adjusting entries

---

# Feature 4 — Member Share Progress

Display ownership progress.

Example:

```text
Required Shares: 100
Owned Shares: 63
Remaining Shares: 37
Progress: 63%
```

Display:

* Paid-up Share Capital
* Current Share Value
* Remaining Amount Needed

Example:

```text
Paid-up Capital

₱6,300

Current Share Value

63 × ₱100
```

Include a visual progress indicator.

---

# Feature 5 — Dashboard Widgets

Display:

* Share Capital Product
* Total Shares Owned
* Paid-up Share Capital
* Share Price
* Remaining Shares Required
* Equity Balance
* Dividend Eligibility
* Voting Eligibility
* Last Purchase Date
* Next Dividend Date (future)
* Share Ownership Percentage

---

# Feature 6 — Audit Trail

Every action must record:

* User
* Branch
* Timestamp
* IP Address
* Device
* Before Values
* After Values
* Remarks

No posted transaction may be edited or deleted.

Use reversal transactions instead.

---

# Feature 7 — Permissions

Define permissions for:

## Board

* View everything
* Approve policy changes

## Manager

* Approve large share purchases
* View reports

## Teller

Can:

* Open Share Capital Accounts
* Buy Shares

Cannot:

* Edit Share Products
* Delete Products
* Change Share Price

## Accounting

* View Journal Entries
* Reconcile Accounts
* Generate Reports

## Auditor

Read-only access

Can view:

* Audit Logs
* Transactions
* Accounting Entries

## System Administrator

* Configure Products
* Manage Permissions
* Configure Accounting Rules

---

# Feature 8 — User Experience

Design the interface to feel like a modern financial institution.

Requirements:

* Clean
* Minimal
* Serious
* Enterprise-grade
* Inspired by Refactoring UI
* Large readable typography
* Neutral color palette
* Excellent whitespace
* Keyboard-first navigation
* Fast workflows
* Responsive
* Built for heavy daily operational use

Avoid unnecessary animations or decorative illustrations.

---

# Future Features

Design the module so it can later support:

* Dividends
* Share Transfers
* Share Redemptions
* Patronage Refunds
* Additional Share Classes
* Joint Ownership
* Corporate Members
* Share Certificates
* Electronic Signatures
* Board Approvals
* Workflow Engine

---

# Expected Deliverables

Generate:

1. User Stories
2. Business Rules
3. Acceptance Criteria
4. Validation Rules
5. Database Schema
6. Entity Relationship Diagram (ERD)
7. Domain Model
8. Rails Models
9. Service Objects
10. State Machines
11. Event-Driven Architecture
12. Accounting Flow
13. Journal Entry Flow
14. API Endpoints
15. Hotwire UI Wireframes
16. Screen Layouts
17. Dashboard Design
18. Audit Logging Strategy
19. Authorization Matrix
20. Future Extension Strategy

---

# Technical Constraints

Optimize the design for:

* Ruby on Rails 8
* Hotwire
* Turbo
* Stimulus
* PostgreSQL
* Solid Queue
* Domain-Driven Design (DDD)
* Service Object Pattern
* Event Sourcing (where appropriate)
* Double-entry accounting
* Banking-grade auditability
* High maintainability
* Future scalability

Prioritize correctness, security, and long-term maintainability over rapid development or demo-quality implementations.
