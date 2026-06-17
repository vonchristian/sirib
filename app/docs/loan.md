# Product Manager Prompt: Loan Lifecycle Module for a Cooperative Core Banking System

## Role

You are an experienced Product Manager specializing in **Core Banking Systems**, **Lending**, and **Cooperative Financial Management**.

Your task is to design a **production-ready Loan Management module** for a cooperative core banking application.

Think like a banking product manager—not a CRUD application developer.

Design workflows that reflect how real cooperative lending operations work, with strong accounting, auditability, and future regulatory compliance.

---

# Business Context

The application is a **Core Banking Platform** built specifically for **Cooperatives**.

Members may apply for different loan products.

The complete loan lifecycle must be supported:

* Loan Application
* Credit Investigation
* Approval Workflow
* Loan Disbursement
* Repayment Schedule
* Collections
* Aging
* Delinquency Monitoring
* Demand Notices
* Loan Restructuring
* Loan Closure

Every financial event must generate proper accounting entries.

All transactions must be fully auditable.

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
* Approval workflows
* Audit logging
* User permissions

Avoid generic CRUD. Design a banking-grade lending system.

---

# Feature 1 — Loan Product

Design the screen for creating Loan Products.

## Basic Information

* Product Code
* Product Name
* Description
* Loan Type

  * Personal
  * Salary
  * Agricultural
  * Business
  * Emergency
  * Housing
  * Vehicle
  * Other
* Status
* Effective Date

---

## Loan Rules

* Minimum Loan Amount
* Maximum Loan Amount
* Minimum Term
* Maximum Term
* Interest Rate
* Interest Method

  * Flat
  * Diminishing Balance
* Interest Frequency
* Repayment Frequency

  * Daily
  * Weekly
  * Semi-monthly
  * Monthly
  * Quarterly
* Grace Period
* Penalty Rate
* Processing Fee
* Service Fee
* Insurance Fee
* Documentary Stamp Tax
* Maximum Number of Active Loans
* Requires Guarantor
* Requires Collateral

---

## Accounting Configuration

Automatically create the required GL mappings.

Example

```text
Loans Receivable
Interest Income
Penalty Income
Unearned Interest
Processing Fee Income
```

Users should not manually configure accounting for every loan.

---

## Validation Rules

Prevent:

* Negative interest rates
* Invalid loan amounts
* Invalid terms
* Duplicate product codes
* Editing accounting mappings once transactions exist

---

# Feature 2 — Loan Application

Create a Loan Application.

## Inputs

* Member
* Loan Product
* Branch
* Loan Amount
* Loan Purpose
* Loan Term
* Payment Frequency
* Guarantors
* Collateral
* Attachments
* Remarks

---

Automatically display:

* Existing Loans
* Outstanding Balance
* Delinquent Loans
* Share Capital Balance
* Savings Balance
* Member Risk Rating
* Credit Score (future)

---

Application Status

* Draft
* Submitted
* Under Review
* Credit Investigation
* Pending Approval
* Approved
* Rejected
* Cancelled

Applications become read-only once submitted.

---

# Feature 3 — Credit Investigation

Credit Officer reviews:

* Member Profile
* Employment
* Income
* Existing Loans
* Guarantors
* Collateral
* Payment History
* Share Capital
* Savings
* Previous Delinquencies

Generate an internal Credit Recommendation.

Possible outcomes:

* Recommend Approval
* Recommend Approval with Conditions
* Recommend Rejection

---

# Feature 4 — Approval Workflow

Support configurable approval levels.

Examples:

* Credit Officer
* Branch Manager
* Credit Committee
* Board of Directors

Approval thresholds should be configurable.

Example:

* Below ₱50,000 → Manager
* ₱50,000–₱500,000 → Committee
* Above ₱500,000 → Board

Track:

* Approver
* Decision
* Comments
* Date
* Digital Signature (future)

---

# Feature 5 — Loan Disbursement

Disbursement methods:

* Cash
* Savings Account
* Check
* Bank Transfer
* Wallet (future)

Automatically compute:

* Processing Fees
* Insurance
* Taxes
* Net Proceeds

Example

```text
Loan Amount
₱100,000

Less Fees
₱3,000

Net Proceeds
₱97,000
```

---

After posting:

Automatically:

* Create Loan Account
* Create Loan Ledger
* Generate Journal Entries
* Create Repayment Schedule
* Record Audit Log
* Update Member Balance

Transactions become immutable.

---

# Accounting Entries

Example

```text
Debit
Loans Receivable

Credit
Cash on Hand
```

Record all fee income separately.

---

# Feature 6 — Repayment Schedule

Automatically generate amortization schedule.

Display:

* Due Date
* Principal
* Interest
* Penalty
* Remaining Balance
* Installment Number
* Status

Support:

* Flat Interest
* Diminishing Balance
* Balloon Payments
* Grace Period
* Irregular Schedules
* Early Payments

---

# Feature 7 — Collections

Create Collection transaction.

Payment Sources:

* Cash
* Savings
* Payroll
* Bank Transfer
* Wallet

Automatically allocate payments:

1. Penalties
2. Interest
3. Principal

Support:

* Partial Payments
* Advance Payments
* Overpayments

Generate official receipts.

---

# Feature 8 — Aging

Automatically classify loans.

Examples:

* Current
* 1–30 Days Past Due
* 31–60 Days
* 61–90 Days
* 91–180 Days
* Over 180 Days
* Non-performing Loan (NPL)

Dashboard should display:

* Aging Summary
* Portfolio at Risk
* Total Delinquent Amount
* Collection Rate
* NPL Ratio

---

# Feature 9 — Notices

Automatically generate notices.

Examples:

* Payment Reminder
* Past Due Notice
* Final Demand
* Legal Notice

Delivery Channels:

* Email
* SMS
* In-app Notification
* Printable Letter

Track:

* Sent Date
* Delivery Status
* Recipient
* Acknowledgement

---

# Feature 10 — Loan Closure

When loan balance reaches zero:

Automatically:

* Mark Loan Paid
* Close Loan Account
* Update Member Status
* Generate Certificate of Full Payment
* Archive Schedule

Loan becomes read-only.

---

# Feature 11 — Loan Restructuring

Support restructuring.

Examples:

* Extend Term
* Reduce Installment
* Change Interest Rate
* Payment Moratorium
* Principal Adjustment
* Refinancing

Maintain complete history.

Never overwrite the original loan.

Create restructuring records linked to the original loan.

---

# Feature 12 — Dashboard Widgets

Display:

* Active Loans
* Outstanding Balance
* Past Due Balance
* Next Due Date
* Collection Today
* Total Interest Earned
* Loan Portfolio
* Portfolio at Risk
* Aging Distribution
* Loan Product Mix
* Collection Performance

---

# Feature 13 — Audit Trail

Record every action.

Store:

* User
* Branch
* Timestamp
* IP Address
* Device
* Before Values
* After Values
* Approval History
* Remarks

No posted financial transaction may be edited.

Corrections require reversal transactions.

---

# Feature 14 — Permissions

## Loan Officer

Can:

* Create Applications
* Edit Drafts
* Conduct Credit Investigation

Cannot:

* Approve Own Loan
* Disburse Loans

---

## Branch Manager

Can:

* Review
* Approve within limits
* View Reports

---

## Credit Committee

Can:

* Approve Committee-Level Loans

---

## Board

Can:

* Approve Large Loans
* Override Policies (with audit)

---

## Teller

Can:

* Accept Payments
* Print Receipts

Cannot:

* Modify Loan Products

---

## Accounting

Can:

* View Journal Entries
* Reconcile Loans
* Generate Financial Reports

---

## Auditor

Read-only access to all loan and accounting records.

---

## System Administrator

Configure:

* Products
* Approval Workflows
* Permissions
* Accounting Rules

---

# Feature 15 — User Experience

The UI should feel like a modern financial institution.

Requirements:

* Clean
* Minimal
* Serious
* Enterprise-grade
* Inspired by Refactoring UI
* Excellent whitespace
* Keyboard-first navigation
* Responsive
* Fast workflows
* Built for high-volume daily operations

Avoid unnecessary animations or decorative illustrations.

---

# Future Features

Design the module to support:

* Co-maker substitution
* Collateral valuation
* Foreclosure
* Loan refinancing
* Batch collections
* Automatic payroll deductions
* AI credit scoring
* AI collection assistant
* SMS payment reminders
* Digital signatures
* Electronic loan documents
* Regulatory reporting
* IFRS 9 Expected Credit Loss (ECL)
* Portfolio stress testing

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
14. Amortization Engine Design
15. Collection Allocation Logic
16. API Endpoints
17. Hotwire UI Wireframes
18. Screen Layouts
19. Dashboard Design
20. Audit Logging Strategy
21. Authorization Matrix
22. Future Extension Strategy

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
* Event-Driven Architecture
* Double-entry Accounting
* Banking-grade Auditability
* High Maintainability
* Horizontal Scalability

Prioritize correctness, financial integrity, auditability, and long-term maintainability over rapid development or demo-quality implementations.
