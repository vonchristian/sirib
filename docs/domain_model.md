# Domain Model

> If a concept does not exist in the real cooperative business, it does not belong in the codebase.

---

## Purpose

This document defines the **Ubiquitous Language**, **core domain concepts**, and **aggregate boundaries** for the Cooperative Banking and Payments Platform.

It is the ground truth for what this system does. If the code disagrees with this document, the code is wrong.

This document ensures:

* Developers speak the same language as the business
* Code maps directly to real-world financial concepts — no translation layer needed
* Domain logic stays consistent across modules
* Boundaries between aggregates are explicit and enforced
* The system can survive audits, new developers, and changing requirements

---

# 1. What Is a Domain Model?

A domain model is not a diagram. It is not a set of database tables. It is not a class hierarchy.

> A domain model is a set of objects that send and receive messages, where each object represents a concept that an accountant, a loan officer, or a cooperative member would recognize.

The objects in this system have names drawn from the business. They encapsulate rules drawn from regulation. They interact through patterns drawn from real cooperative operations.

Every object in the domain model answers two questions:

1. **What messages does this object receive?** (What can you ask it to do?)
2. **What messages does this object send?** (What does it tell other objects?)

If an object cannot be described in those terms, it is not a domain object. It is plumbing.

---

# 2. Ubiquitous Language

These are the **official business terms** used across code, UI, APIs, and discussions. A term may not be used in any other sense. A concept may not be introduced without a business term.

If you cannot name it in business language, you do not understand what it is.

---

## 2.1 Core Entities

### Loan

A financial agreement where a member borrows money under defined terms and repayment schedule.

A Loan is not a database row. It is a state machine that protects the integrity of a financial agreement.

**Receives messages like:**
- `disburse!` — release funds to the member
- `apply_repayment!(amount)` — record a payment against this loan
- `assess_penalties!` — evaluate and apply late fees
- `mark_overdue!` — transition to delinquent status

**Sends events like:**
- `LoanDisbursed` — funds have been released
- `LoanOverdue` — repayment is late
- `LoanClosed` — all obligations satisfied

---

### LoanProduct

Defines the rules for a type of loan.

Contains:

* interest rate rules (fixed, variable, tiered, promotional)
* term limits (minimum, maximum, default)
* fees (origination, late payment, prepayment)
* eligibility rules (member tenure, savings requirements, credit score minimum)
* collateral requirements

LoanProduct is NOT a Loan. A LoanProduct is a template. A Loan is an instance of that template. Confusing the two leads to systems where changing a product breaks existing loans.

---

### LoanApplication

A request by a member to obtain a loan.

**States:**

```
pending → approved → Loan (creates the loan)
       ↘ rejected   → archived
       ↘ withdrawn  → archived
```

A LoanApplication may become a Loan through the approval process. It does not mutate into a Loan directly — it goes through an explicit transition that emits a `LoanApplicationApproved` event.

Once approved or rejected, a LoanApplication is immutable. Past decisions are not revisited without a new application.

---

### Loan (Active)

An active financial obligation after approval and disbursement.

A Loan contains:

* principal — the amount borrowed
* interest rules — derived from LoanProduct at creation time
* repayment schedule — the plan of future payments
* current status

**States:**

```
active → delinquent → closed
      ↘ written_off
```

Each state transition is a deliberate, tested method with preconditions and guards.

---

### RepaymentSchedule

A generated plan of expected payments over time.

Contains:

* due dates — schedule of payment dates
* principal allocation — how much principal per installment
* interest allocation — how much interest per installment
* penalties — if applicable for late payment scenarios

RepaymentSchedule is immutable once generated, unless the loan is restructured. Restructuring creates a new schedule; the old one is archived for audit.

---

### Repayment

A payment made by a member toward a Loan.

A Repayment is a financial event. It captures:

* who paid
* how much
* when
* which loan it was for
* how it was allocated

A Repayment is always applied through a RepaymentDistribution. The Repayment itself is just "someone gave us money." The Distribution is "where that money went."

---

### RepaymentDistribution

The allocation of a Repayment across financial obligations. This is where the business rules live.

Allocation is deterministic and follows this order:

1. **Fees** — late fees, processing fees, penalty charges
2. **Interest** — accrued but unpaid interest
3. **Principal** — the remaining principal balance

This order is not arbitrary. It is a business decision. Fees are collected first to discourage late payment. Interest is collected next because the cooperative's cost of capital must be covered. Principal is reduced last.

Distribution rules are:

* deterministic — given the same inputs, always the same output
* auditable — each distribution creates an immutable record
* non-reversible — once posted, a distribution cannot be reallocated

```ruby
# What the distribution logic looks like:
distribution = RepaymentDistribution.new(repayment: repayment, loan: loan)
distribution.apply_order = [:fees, :interest, :principal]

distribution.allocate!
# => fees_paid: 500, interest_paid: 1_000, principal_paid: 8_500
```

---

### Member

A cooperative member with financial identity.

A Member is the identity boundary of the system. It contains:

* legal identity (name, identifiers, contact)
* membership status (active, inactive, suspended, terminated)
* account relationships (which savings accounts, which loans)

A Member does not contain financial state. The Member's savings balance is not stored on the Member. It is a query across context boundaries: the Payments context knows about accounts, the Lending context knows about loans. The Member is who they belong to.

---

### SavingsAccount

A deposit account owned by a Member.

Used for:

* deposits and withdrawals
* loan disbursement (funds flow here before the member withdraws)
* repayment collection (funds flow from here to the loan)

A SavingsAccount is not a wallet. It is a ledger of events. The balance is derived, not stored. Every deposit, withdrawal, and fee creates an immutable transaction entry.

---

### CashSession

A daily operational session of a teller or clerk.

A CashSession tracks:

* opening balance — how much cash the teller started with
* cash in — member deposits, loan payments
* cash out — member withdrawals, loan disbursements
* closing balance — reconciled at end of day
* difference — any variance that must be explained

CashSession exists because in cooperative banking, cash has to balance at the end of every day. This is not a technical concern. It is an operational reality.

---

### Transaction

A financial event recorded in the system.

Types:

* `deposit` — funds added to an account
* `withdrawal` — funds removed from an account
* `loan_disbursement` — funds released to a member
* `repayment` — funds received from a member
* `adjustment` — correction of a previous error (never a deletion)

**Transactions are immutable.** You do not delete a transaction. You write an offsetting transaction. This is the foundation of auditability.

---

### Collateral

An asset pledged against a Loan.

Used for:

* risk mitigation — the cooperative has recourse if the loan defaults
* loan approval decisions — collateral affects loan-to-value ratios, interest rates
* regulatory compliance — some loan types require collateral

Collateral may be:

* **released** — when the loan is fully repaid
* **seized** — when the loan defaults and the cooperative takes possession
* **revalued** — when the asset's value changes significantly

---

### RiskAssessment

A computed evaluation of borrower risk.

Contains:

* score — a numeric evaluation (e.g., 0 to 1000)
* grade — a letter grade (e.g., A, B, C, D, E)
* risk factors — what drove the score up or down
* explanation — human-readable reasoning

RiskAssessment is derived, not stored as input. It is computed from member data, loan data, and external sources. The computation is deterministic. Same inputs, same output, every time.

---

# 3. Domain Boundaries (Bounded Contexts)

The system is divided into bounded contexts. Each context owns its data, its logic, and its invariants. A context does not reach into another context and modify state.

This is not an architectural preference. It is a survival mechanism for a system that handles money. When every context owns its data, no context can corrupt another's data by accident.

---

## 3.1 Lending Context

**Responsible for:**

* LoanProducts — defining what kinds of loans exist
* LoanApplications — accepting, processing, and deciding on applications
* Loans — managing the lifecycle of active loans
* RepaymentSchedules — generating and maintaining payment plans
* Repayment logic — allocating payments across fees, interest, and principal

**Rules:**

* Loan lifecycle is owned here — no other context transitions a loan's state
* Repayment schedule generation happens here — the schedule is a lending concern
* Risk assessment is consumed, not owned — Lending asks Risk for scores, Risk computes them

**Does NOT do:**

* move money (that belongs to Payments)
* store member identity (that belongs to Member)
* compute risk scores (that belongs to Risk)

---

## 3.2 Payments Context

**Responsible for:**

* Transactions — every financial event recorded immutably
* Repayments — receiving and recording payments
* SavingsAccount movements — deposits, withdrawals, balance queries
* External payment integrations — gateways, EFT, checks

**Rules:**

* All money movement flows through this context. If money moves, Payments knows about it.
* No loan rules are defined here. Payments handles the mechanics, not the policy.
* No interest calculation happens here. Payments records what the Lending context tells it to record.

**Does NOT do:**

* decide how much interest to charge (that belongs to Lending)
* approve or reject loan applications (that belongs to Lending)
* assess penalties (that belongs to Lending)

---

## 3.3 Member Context

**Responsible for:**

* Member profiles — identity, contact, demographics
* Identity verification — KYC, document management
* Membership status — active, inactive, suspended, terminated
* Account ownership links — which accounts and loans belong to which member

**Rules:**

* No financial calculations. A Member context never computes a balance, an interest rate, or a risk score.
* No loan logic. A Member context never transitions a loan state.
* Pure identity and relationships. If it does not answer "who is this person?" or "what belongs to them?", it does not belong here.

---

## 3.4 Risk Context

**Responsible for:**

* RiskAssessment generation — computing and storing risk evaluations
* Scoring models — formulas, weights, thresholds
* Factor analysis — what drives risk up or down

**Rules:**

* Stateless computation is preferred. Risk assessment should be deterministic.
* Consumes data from Lending, Member, and Payments — but does not modify them.
* Produces immutable RiskAssessment results. Once computed, a risk assessment is a historical fact.

---

## 3.5 Treasury / Accounting Context

**Responsible for:**

* Ledger entries — the official record of every financial event
* Reconciliation — matching internal records to external statements
* Financial reporting integrity — balance sheets, income statements, regulatory reports

**Rules:**

* All financial events must eventually be reflected here. If it is not in the ledger, it did not happen.
* Double-entry bookkeeping rules apply. Every debit has a credit. Every credit has a debit.
* No business logic for lending or risk. Accounting records events; it does not create them.

---

# 4. Aggregate Boundaries

An aggregate is a cluster of domain objects that must be treated as a unit for data consistency. The aggregate root is the only entry point. All external access goes through the root.

This rule exists for a simple reason: if you let every object modify every other object, you lose the ability to reason about any individual change. Aggregates are how you control complexity. They are boundaries of invariants.

---

## 4.1 Loan Aggregate

**Root:** `Loan`

**Contains:**
* Loan
* RepaymentSchedule
* Collateral references (not full objects — just identifiers)

**Rules:**

* Only Loan can mutate its own state. No external object calls `loan.update(status: :delinquent)`. Only `loan.mark_delinquent!` can do that.
* RepaymentSchedule cannot be modified externally. Once generated, it is read-only.
* Repayment application must go through Loan. You do not create a RepaymentDistribution without the Loan knowing about it.

**Design rationale:** The Loan aggregate must always be consistent. If someone modifies the schedule without the Loan knowing, or applies a repayment directly, the Loan's view of its own state becomes a lie.

---

## 4.2 LoanApplication Aggregate

**Root:** `LoanApplication`

**Contains:**
* applicant data snapshot (copied from Member at time of application)
* requested terms (product, amount, tenor)
* approval/rejection decision (who decided, when, why)

**Rules:**

* Cannot mutate into a Loan directly. LoanApplication produces an event; a separate process creates the Loan.
* Must go through the approval process. No shortcuts.
* Immutable after approval or rejection. A historical record of a business decision.

---

## 4.3 Repayment Aggregate

**Root:** `Repayment`

**Contains:**
* Repayment
* RepaymentDistribution

**Rules:**

* Distribution is computed at creation. You determine the allocation once, when the payment arrives.
* Cannot be reallocated after posting. Money that has been allocated cannot be un-allocated.
* Must reference the Loan but not modify it directly. The Repayment tells the Loan "I have been applied." The Loan decides what to do with that information.

---

## 4.4 Member Aggregate

**Root:** `Member`

**Contains:**
* identity
* membership status
* account and loan links

**Rules:**

* No financial state inside the aggregate. The Member does not cache its balance, its loan total, or its risk score.
* Acts as an identity boundary. The Member is the answer to "who is this person?"

---

## 4.5 Transaction Aggregate

**Root:** `Transaction`

**Contains:**
* transaction metadata (type, timestamp, source)
* debit entries
* credit entries

**Rules:**

* Immutable. Once recorded, a Transaction is never changed.
* Append-only. Corrections are new transactions, not edits to old ones.
* Must be reconcilable in the Accounting context. Every transaction must eventually match a ledger entry.

---

# 5. Aggregate Interaction Rules

## 5.1 The Golden Rule

> Aggregates NEVER directly mutate other aggregates.

This is not a guideline. It is the single most important architectural constraint in the system.

If you find yourself writing:

```ruby
# BAD — direct mutation across aggregate boundary
loan = Loan.find(id)
member.update(last_loan_date: Date.today)  # Loan mutating Member
```

Stop. You are coupling domains. You are creating hidden dependencies. You are building a system that cannot be changed without breaking everything.

Instead:

```ruby
# GOOD — event-driven communication
loan.disburse!
loan.events.last # => LoanDisbursed event
# Payments context subscribes to LoanDisbursed and creates the Transaction
```

---

## 5.2 Communication Channels

Aggregates communicate through exactly three mechanisms:

| Mechanism | Use Case |
|---|---|
| **Domain Events** | One aggregate tells the world something happened. Other aggregates react. |
| **Application Services** | Orchestration across aggregates. The service calls multiple aggregates but contains no domain logic. |
| **Repositories** | Data retrieval only. Never mutation. |

---

## 5.3 Example Flow: Loan Disbursement

```
1. Lending:       Loan approves disbursement via loan.approve!
2. Lending:       Loan emits LoanDisbursed event
3. Payments:      Subscribes to LoanDisbursed, creates Transaction
4. Payments:      SavingsAccount balance updated (as derived from transactions)
5. Accounting:    Subscribes to TransactionCreated, records ledger entry
```

No step involves one aggregate calling a method on another aggregate's internal object.

---

## 5.4 Example Flow: Repayment

```
1. Payments:      Payment received (cash, EFT, check)
2. Payments:      Transaction created
3. Lending:       Loan receives `apply_repayment!` message
4. Lending:       Loan computes RepaymentDistribution
5. Lending:       Loan emits RepaymentApplied event
6. Accounting:    Records ledger entry
```

The loan computes the distribution because allocation rules are lending logic. Payments does not decide how to allocate — it only records that money was received.

---

# 6. Domain Events

Events are the source of truth for cross-context communication. If context A needs context B to do something, context A emits an event. Context B subscribes.

This is how real-world organizations work. The lending department does not call the accounting department and say "update the ledger." The lending department completes its work and the resulting paperwork triggers the accounting department's process.

## 6.1 Core Events

| Event | Trigger | Consumers |
|---|---|---|
| `LoanApplicationApproved` | LoanApplication approved | Lending (create Loan), Risk (update portfolio) |
| `LoanDisbursed` | Loan disbursed | Payments (create Transaction), Accounting (ledger entry) |
| `RepaymentReceived` | Payment applied to loan | Lending (update balance), Accounting (ledger entry) |
| `LoanOverdue` | Payment missed | Lending (assess penalties), Notifications (alert member) |
| `LoanClosed` | Loan fully repaid | Lending (archive), Collateral (release assets) |
| `CollateralReleased` | Collateral returned | Member (update records) |

## 6.2 Event Rules

Events are:

* **Immutable** — once recorded, never changed
* **Append-only** — new events are added, old events are preserved
* **Auditable** — every event carries a timestamp, a source, and a reason

An event is a fact. Facts do not change. You cannot unsay what an event said. You can only emit a compensating event.

---

# 7. Data Ownership

| Context | Owns This Data | Does Not Own |
|---|---|---|
| Lending | Loans, Applications, Schedules, Distributions | Payments, Identity, Scores |
| Payments | Transactions, Repayments, Account Movements | Loan terms, Risk data |
| Member | Identity, Status, Relationships | Balances, Loans |
| Risk | RiskAssessments, Scoring models | Member data, Loan details |
| Accounting | Ledger entries, Reports | Transaction records (references them) |

Each context is sovereign over its data. Another context may query it. No context may modify what it does not own.

---

# 8. Naming Conventions

Names are the most important documentation you will ever write. Every name is either a commitment to clarity or an acceptance of confusion.

**Methods must be commands or queries in business language:**

Good:

```
approve_application
disburse
record_repayment
calculate_risk
assess_penalties
release_collateral
reconcile_session
```

Bad:

```
process
handle
do_work
execute_service
run
perform_action
update_status
```

**Why this matters:** `process` tells you nothing. `disburse` tells you exactly what happens. When you name a method `process`, you are deferring understanding to the reader. Every time someone has to read the implementation to understand what a method does, you have failed them.

---

# 9. Consistency Rules

These rules exist because financial systems cannot tolerate inconsistency. They are not suggestions.

* **Money is always an explicit type.** Never use a raw integer or float for a monetary value. Every financial amount is a `Money` object with a currency and a precision.
* **Dates always have business meaning.** `due_date`, `disbursed_at`, `last_payment_date` — never `date_1`, `date_2`. If a date does not have a business name, it does not belong on the object.
* **State transitions must be explicit methods.** `def disburse!`, `def mark_overdue!`, `def close!` — never `update(status: :disbursed)`. The method is where guards, invariants, and side effects live.
* **No implicit state changes.** A callback that transitions state as a side effect of something else is a bug waiting to happen. State changes are deliberate acts.
* **Computed values are not stored unless necessary.** A balance derived from transactions is not cached on the Member. A risk score is recomputed on request, not stored as truth.

---

# 10. Design Principles

## 10.1 Testability Is a Design Property

> A domain model that is hard to test is a domain model with the wrong design.

If setting up a test requires twelve factory calls and mocking three services, the aggregate boundary is wrong. The object knows too much. It reaches across too many contexts.

The Loan aggregate should be testable with two calls: `create(:loan)` and `loan.disburse!`. If it needs more than that, the design is coupling too tightly.

## 10.2 Design for Change

> The purpose of design is to reduce the cost of change.

Do not predict what will change. Instead, organize the code so that the most likely changes — new loan products, revised interest calculations, different fee structures — affect the fewest files.

A well-designed domain model makes common changes safe and rare changes possible.

## 10.3 Events Over Callbacks

Callbacks are hidden logic. Events are explicit communication.

```ruby
# BAD — hidden logic in a callback
class Loan
  after_save :notify_member_if_disbursed
end

# GOOD — explicit event emission
class Loan
  def disburse!
    # ... state transition ...
    events << LoanDisbursed.new(loan_id: id, amount: principal)
  end
end
```

Events can be subscribed to, logged, replayed, and audited. Callbacks are invisible until they break.

---

# 11. Anti-Patterns (STRICTLY FORBIDDEN)

These are not "try to avoid." They are forbidden. Every single one has caused real, verified problems in financial systems.

* Service objects that mix contexts (e.g., `LoanPaymentService`, `LoanRiskService` — which context owns it? neither, and that is the problem)
* Direct cross-model updates between aggregates (you are coupling domains that should be independent)
* Fat god models (an object that does everything is an object that cannot be changed)
* Polymorphic abuse for unrelated entities (just because they share a column type does not mean they share a concept)
* Storing computed values without justification (if you cache a computed value, document why the computation is too expensive to repeat)
* Business logic inside controllers (controllers are routers, not decision-makers)
* Mixing accounting logic inside lending (accounting records; lending decides)

---

# 12. System Philosophy

This system is not a CRUD application. It is a **financial operating system for cooperatives**.

Every object must represent a **real financial truth**, not a database table.

A `Loan` is not a row in a `loans` table. It is a financial agreement with rules, invariants, and state transitions. The table is how it is stored. The object is what it is.

A `Transaction` is not a row in a `transactions` table. It is an immutable record of value moving between accounts. The table is the implementation. The concept is the truth.

> Code is how you express the domain. The domain is not how you organize your code.

Design the domain first. Implement it second. If you start from the database schema, you will end up with a CRUD app that happens to handle money. If you start from the domain, you will end up with a financial system that happens to use Rails.

---

# 13. Final Rule

> If a concept does not exist in the real cooperative business, it does not belong in the codebase.

Before adding any new class, method, or attribute, ask three questions:

1. What is the business term for this?
2. Does a loan officer, teller, or accountant recognize this concept?
3. Will this appear in an audit trail?

If you cannot answer all three, the concept does not belong in the domain model. It may belong in infrastructure, in configuration, or nowhere at all.
