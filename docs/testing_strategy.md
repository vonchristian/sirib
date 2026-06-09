# Testing Strategy

## Purpose

This document defines the **testing strategy** for the Cooperative Banking Platform.

It ensures:

* Financial correctness is verifiable
* Business logic is always testable
* AI-generated code remains safe and predictable
* Regression risk is minimized
* Domain behavior is always protected by tests

Testing is not optional. It is part of the system design.

---

# 1. Core Philosophy

We test:

> behavior, not implementation

We do NOT test:

* internal private methods
* framework behavior (Rails already does this)
* implementation details that can change

---

# 2. Test Pyramid

We use a strict test hierarchy:

## 2.1 System Tests (Few, Critical Flows)

Purpose:

* validate full user journeys
* ensure system integration correctness

Examples:

* Loan application → approval → disbursement → repayment
* Member registration → account creation → loan eligibility
* Cash session opening → transactions → end-of-day reconciliation

Rules:

* slow but comprehensive
* must simulate real user behavior
* must use real DB interactions

---

## 2.2 Request Specs (API Layer)

Purpose:

* validate API correctness
* ensure controller behavior is correct

Examples:

* POST /loans
* POST /repayments
* GET /members/:id

Rules:

* no business logic assertions
* only input/output validation
* must not mock domain objects

---

## 2.3 Model Specs (Domain Logic - MOST IMPORTANT)

Purpose:

* validate business rules
* enforce domain correctness

Examples:

* loan.disburse!
* repayment.apply!
* risk_score.calculate

Rules:

* MUST be exhaustive for domain logic
* no mocking of internal logic
* test real state transitions

---

## 2.4 Unit Specs (Value Objects & Calculators)

Purpose:

* test pure logic objects

Examples:

* Money
* InterestCalculator
* RiskScoreCalculator

Rules:

* no database
* deterministic outputs only

---

# 3. Testing Domain Rules

## 3.1 State Transitions Must Be Tested

Example:

```ruby id="t1l9xq"
describe Loan do
  it "transitions from approved to disbursed" do
    loan = create(:loan, status: :approved)

    loan.disburse!

    expect(loan.status).to eq("disbursed")
  end
end
```

---

## 3.2 Financial Accuracy Must Be Tested

All money flows must be validated:

* principal
* interest
* penalties
* fees

Example:

* repayment allocation correctness
* amortization schedule correctness

---

## 3.3 Edge Cases Are Mandatory

Must test:

* overdue loans
* partial payments
* zero payments
* invalid repayment attempts
* duplicate transactions

---

# 4. System Test Standards

## 4.1 Realistic Scenarios Only

System tests must reflect:

* real cooperative workflows
* real roles (teller, officer, member)

Not:

* artificial unit flows
* contrived test-only logic

---

## 4.2 No Mocking Rule

System tests MUST NOT:

* mock database
* mock services
* mock internal logic

Only external systems MAY be stubbed:

* payment gateways
* SMS services

---

## 4.3 Full Stack Validation

System tests validate:

* UI (if applicable)
* controllers
* domain logic
* database state

---

# 5. Request Spec Standards

## 5.1 API Contract Validation

Request specs must ensure:

* correct status codes
* correct payload structure
* correct authorization behavior

---

## 5.2 No Business Logic Assertions

Forbidden:

* checking loan calculations
* checking risk scoring
* verifying internal calculations

Those belong in model specs.

---

# 6. Model Spec Standards

## 6.1 Primary Source of Truth Tests

Model specs must validate:

* state transitions
* validations
* domain invariants
* business rules

---

## 6.2 Deterministic Behavior Only

Tests must not depend on:

* random values
* external APIs
* system time (unless explicitly controlled)

---

## 6.3 Time Handling

Use:

* `travel_to`
* frozen time helpers

Never rely on real time.

---

# 7. Value Object Testing

Value objects must be:

* fully deterministic
* fully isolated

Examples:

* Money arithmetic
* Interest calculations
* Risk scoring logic

Rules:

* no database
* no mocks
* pure inputs → outputs

---

# 8. Factory Strategy

We use factories for setup only.

Rules:

* factories must be minimal
* no business logic inside factories
* no hidden state generation

Bad:

* factory that creates full loan lifecycle

Good:

* factory that creates base loan only

---

# 9. Test Data Rules

## 9.1 Explicit is Required

Tests must clearly define:

* loan status
* amounts
* dates

No ambiguous defaults.

---

## 9.2 Avoid Overuse of Fixtures

Prefer factories or explicit setup.

---

# 10. Mocking Rules

## 10.1 Allowed Mocking

ONLY allowed for:

* external APIs
* third-party services

Examples:

* PaymentGateway
* SMSGateway

---

## 10.2 Forbidden Mocking

Never mock:

* ActiveRecord models
* domain objects
* internal services
* business logic

---

## 10.3 Why

Mocking domain logic hides:

* real bugs
* incorrect assumptions
* integration failures

---

# 11. Test Naming Standards

Tests must describe behavior in business language.

Good:

```ruby id="n7p2kq"
it "disburses loan and creates repayment schedule"
```

Bad:

```ruby id="m1x9ab"
it "calls service and updates DB"
```

---

# 12. Test Structure (AAA Pattern)

All tests must follow:

* Arrange
* Act
* Assert

Example:

```ruby id="c8xk2q"
# Arrange
loan = create(:loan, status: :approved)

# Act
loan.disburse!

# Assert
expect(loan.status).to eq("disbursed")
```

---

# 13. Database State Assertions

We always verify:

* persisted state
* side effects in DB

Examples:

* transactions created
* repayment records updated
* ledger entries written

---

# 14. Performance Testing (Lightweight)

We do NOT over-invest in performance tests early.

But we must ensure:

* no obvious N+1 queries
* no unbounded queries
* pagination exists where needed

---

# 15. Security Testing

Must validate:

* authorization rules
* role-based access
* forbidden actions

Examples:

* member cannot approve loans
* teller cannot change risk score

---

# 16. Regression Safety

Any bug fix MUST include:

* failing test reproducing bug
* passing test after fix

No exception.

---

# 17. AI Code Testing Rules

When AI generates code:

## 17.1 Mandatory Test Generation

AI MUST:

* generate model specs for domain logic
* generate request specs for APIs
* update system tests if workflows change

---

## 17.2 No Test-Free Code

Any code without tests is considered:

> incomplete

---

## 17.3 AI Verification Checklist

Before marking task complete:

* Are state transitions tested?
* Are edge cases covered?
* Are money flows validated?
* Are system flows updated?
* Are mocks used correctly?

If any answer is no → task is NOT done.

---

# 18. Coverage Expectations

We prioritize:

* 100% coverage of domain logic
* high coverage of financial flows
* moderate coverage of UI

We do NOT optimize for:

* line coverage metrics alone
* meaningless test quantity

---

# 19. Anti-Patterns (STRICTLY FORBIDDEN)

* mocking domain objects
* testing private methods
* testing Rails framework behavior
* overusing system tests for unit logic
* skipping edge cases in financial flows
* brittle UI-only assertions
* tests without business meaning

---

# 20. Definition of Done (Testing Perspective)

A feature is NOT complete unless:

* model specs exist for all domain logic
* request specs validate API behavior
* system tests validate full flow (if applicable)
* edge cases are covered
* regression test added if bug-related
* no mocked business logic exists

---

# 21. Final Rule

> If a behavior is not tested, it is not part of the system.
