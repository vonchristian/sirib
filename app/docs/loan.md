# Product Manager Prompt: Loan Operations Module (Core Banking System for Cooperatives)

## Role

You are an expert Product Manager specializing in **Core Banking Systems**, **Lending Operations**, and **Financial Accounting Integration** for cooperative institutions.

Your task is to design a **production-grade Loan Operations module** that serves as the execution layer for the entire lending lifecycle.

This is not a CRUD loan tracker.

This is a **financial operations engine that executes, controls, and accounts for lending activities**.

---

# Business Context

The cooperative operates a full lending business under strict financial control and audit requirements.

Loan operations must integrate with:

* Treasury (cash movement)
* Accounting (double-entry GL posting)
* Member accounts (savings, share capital)
* Risk and compliance systems
* Collections and delinquency management

Every loan action is a **financial event**, not just a record update.

---

# Core Design Principle

> “A loan is not data. A loan is a lifecycle of financial obligations.”

Every loan event must:

* Produce accounting entries
* Update subledgers
* Trigger audit logs
* Be fully traceable
* Be immutable after posting (reversal only)

---

# Feature 1 — Loan Product Engine

Defines how loans behave.

## Configuration Fields

* Product Code
* Product Name
* Loan Type

  * Personal
  * Salary
  * Agricultural
  * Business
  * Emergency
  * Housing
  * Vehicle
* Interest Rate
* Interest Method

  * Flat
  * Declining Balance
* Term Range (min/max months)
* Loan Amount Range (min/max)
* Payment Frequency

  * Daily
  * Weekly
  * Semi-monthly
  * Monthly
* Grace Period Rules
* Penalty Rules
* Fees (processing, insurance, service)
* Collateral Requirement
* Guarantor Requirement
* Max Active Loans per Member

---

## Accounting Mapping

Each product must map to GL accounts:

* Loans Receivable
* Interest Income
* Penalty Income
* Fees Income
* Unearned Interest (if applicable)

---

# Feature 2 — Loan Application Lifecycle

## Status Flow

* Draft
* Submitted
* Under Review
* Credit Investigation
* Approved
* Rejected
* Cancelled

---

## Rules

* Submitted applications become read-only
* Credit investigation must capture financial profile snapshot
* No loan can proceed without approval workflow completion

---

# Feature 3 — Credit Assessment Engine

Evaluates borrower risk.

## Inputs

* Member financial history
* Existing loans
* Savings balance
* Share capital balance
* Payment behavior
* Guarantors
* Collateral value

---

## Outputs

* Credit Score (internal)
* Risk Tier

  * Low
  * Medium
  * High
* Recommendation

  * Approve
  * Conditional Approve
  * Reject

---

# Feature 4 — Approval Workflow Engine

Configurable multi-level approval.

## Approval Levels

* Loan Officer
* Branch Manager
* Credit Committee
* Board (high-value loans)

---

## Rules

* Approval thresholds based on loan amount
* No self-approval
* All approvals are immutable records
* Digital signature support (future-ready)

---

# Feature 5 — Loan Disbursement Engine

Executes fund release.

## Disbursement Methods

* Cash
* Bank Transfer
* Check
* Savings Offset (internal)
* Wallet (future)

---

## System Behavior

Before posting:

* Validate approval completion
* Validate account status
* Compute net proceeds

---

## Net Disbursement Formula

```text id="loan_net_001"
Net Proceeds =
Loan Amount
- Processing Fee
- Insurance Fee
- Taxes
```

---

## Accounting Entry

```text id="loan_disb_001"
Debit: Loans Receivable
Credit: Cash / Bank
```

---

## Post-Disbursement Actions

* Create loan account
* Generate amortization schedule
* Create subledger entry
* Trigger audit log
* Emit LoanDisbursed event

---

# Feature 6 — Amortization Engine

Generates repayment schedule.

## Supports

* Flat interest
* Declining balance
* Balloon payments
* Grace periods
* Irregular schedules

---

## Schedule Fields

* Due Date
* Principal
* Interest
* Fees
* Penalty Accrual
* Remaining Balance
* Status

---

# Feature 7 — Loan Repayment Engine

## Payment Allocation Priority

1. Penalties
2. Interest
3. Principal

---

## Partial Payments Supported

System must correctly allocate partial payments across components.

---

## Accounting Entry

```text id="loan_pay_001"
Debit: Cash
Credit: Interest Income
Credit: Loans Receivable
```

---

# Feature 8 — Loan Restructuring Engine

Allows modification without destroying history.

## Allowed Changes

* Term extension
* Interest rate adjustment
* Payment rescheduling
* Principal restructuring
* Moratorium (payment holiday)

---

## Rule

* Original loan remains unchanged
* New restructuring record is linked
* New amortization schedule is generated

---

# Feature 9 — Loan Closure Engine

Triggers when:

* Balance = 0

## Actions

* Mark loan as CLOSED
* Archive schedule
* Generate closure certificate
* Lock account (read-only)

---

# Feature 10 — Delinquency & Aging Engine

## Aging Buckets

* Current
* 1–30 days
* 31–60 days
* 61–90 days
* 91–180 days
* Over 180 days (NPL)

---

## Metrics

* Portfolio at Risk (PAR)
* Non-performing loans
* Collection efficiency
* Default rate

---

# Feature 11 — Collection Operations

## Channels

* Cash
* Bank transfer
* Payroll deduction
* Savings offset

---

## System Behavior

* Auto-allocate payments
* Update amortization schedule
* Update GL entries
* Generate official receipt

---

# Feature 12 — Loan Notices Engine

Automated notifications:

* Payment reminder
* Past due notice
* Demand letter
* Final notice

---

## Channels

* SMS
* Email
* In-app notification
* Printable letters

---

# Feature 13 — Accounting Integration

Every loan event generates:

## Journal Entries

* Disbursement
* Repayment
* Interest accrual
* Penalty posting
* Write-offs

---

## Rule

> No loan exists without accounting records.

---

# Feature 14 — Audit Trail (Mandatory)

Every action must record:

* User/system actor
* Branch
* Timestamp
* IP address
* Device
* Before state
* After state
* Approval chain
* Reference ID

---

## Rule

* Immutable records
* Only reversal entries allowed

---

# Feature 15 — Permissions Model

## Loan Officer

* Create applications
* Initiate credit investigation

## Branch Manager

* Approve loans within limits
* View portfolio

## Credit Committee

* Approve large loans

## Teller

* Accept payments

## Accounting

* View financial entries

## Auditor

* Full read-only access

## Admin

* Configure loan products and workflows

---

# Feature 16 — UX Requirements

The system must feel:

* Financial-grade
* Minimal
* Fast for operations staff
* Audit-first
* Keyboard efficient
* No clutter
* Clear balance visibility at all times

---

# Event-Driven Architecture

Loan operations emit events:

* LoanCreated
* LoanApproved
* LoanDisbursed
* PaymentReceived
* LoanRestructured
* LoanClosed
* LoanDefaulted

Events trigger:

* Accounting engine
* Treasury movement
* Notifications
* Reporting engine

---

# Future Enhancements

Design for:

* AI credit scoring
* Fraud detection
* Automated underwriting
* Real-time risk scoring
* IFRS 9 ECL provisioning
* Predictive delinquency alerts
* Digital loan contracts
* API-based lending partnerships
* Automated restructuring suggestions

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
11. Amortization Engine Design
12. Collection Allocation Logic
13. Accounting Flow
14. Journal Entry Design
15. API Endpoints
16. Hotwire UI Wireframes
17. Screen Layouts
18. Dashboard Design
19. Audit Logging Strategy
20. Authorization Matrix
21. Event-Driven Architecture
22. Risk & Delinquency Engine Design
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
* High reliability financial systems

---

# Core Principle

> A loan system is not a record system. It is a controlled financial obligation engine with accounting truth at its core.
