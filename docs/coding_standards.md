# Coding Standards (Rails + Ruby)

> If a piece of code cannot be explained in simple business language, it is too complex.

---

## Purpose

This document defines the **strict coding standards** for the Cooperative Banking Platform.

It exists to ensure:

* Consistent code across all contributors (human or AI)
* Predictable Rails structure — any developer can open any file and know what to expect
* High maintainability over time — the codebase ages well
* Domain logic clarity — business rules are not buried in plumbing
* Minimal architectural drift — the code stays faithful to the design

These rules are **mandatory**, not optional. They are lessons learned from financial systems that have failed because someone broke a rule "just this once."

---

# 1. Core Philosophy

We optimize for:

* **Clarity over cleverness** — the most clever code is the code that is obvious
* **Explicitness over magic** — if it is not visible, it is not debuggable
* **Composition over inheritance** — inheritance is coupling; composition is choice
* **Domain language over technical language** — code must tell a business story
* **Small objects over large frameworks** — Rails is the framework; the domain is the system

> Rails is the framework. The domain is the system. Never confuse the two.

---

# 2. Ruby Style

## 2.1 Write Idiomatic Ruby, But Not Clever Ruby

Use the language's idioms. Blocks, iterators, `unless`, `&&` and `||` returns — these are idiomatic Ruby.

Do NOT use the language's obscurities. One-liner methods that require a comment to parse are not clever. They are a tax on every future reader.

```ruby
# GOOD — clear and idiomatic
def disburse!
  return if disbursed?
  update!(status: :disbursed, disbursed_at: Time.current)
  events << LoanDisbursed.new(loan_id: id)
end

# BAD — "clever"
def disburse!; update!(status: :disbursed, disbursed_at: Time.current).then { events << LoanDisbursed.new(loan_id: id) } if !disbursed?; end
```

## 2.2 No Obscure Metaprogramming

Metaprogramming is a tool of last resort. It makes code invisible. Methods that do not exist in the source code are methods that cannot be found by grep.

Allowed:
* `delegate` — this is standard Rails and well-understood
* `attr_reader`/`attr_accessor` — standard Ruby
* `has_many`/`belongs_to` — standard Rails

Requires justification:
* `method_missing` — almost never needed
* `define_method` — almost never needed
* `class_eval` with string arguments — almost never needed
* `included`/`class_methods` in concerns — use sparingly

## 2.3 No Monkey Patching Core Classes

Do not modify `String`, `Integer`, `Hash`, `Array`, or other core Ruby classes unless explicitly justified and documented.

If you must add a method to a core class, it must:
1. Be in a separate file with a clear naming convention
2. Have a comment explaining why it is necessary
3. Have tests

```ruby
# ACCEPTABLE — if justified and documented
# config/initializers/core_extensions/money_formatting.rb
class Integer
  # Used for formatting centavos amounts in views
  def to_money(currency = "PHP")
    Money.new(self, currency)
  end
end
```

---

# 3. Method Design

## 3.1 One Method, One Thing

Every method does exactly one thing. If you cannot describe it in a sentence without "and," split it.

```ruby
# BAD — "disburses the loan AND creates the transaction AND sends the notification"
def disburse!
  update!(status: :disbursed)
  Transaction.create!(...)
  Notification.send!(...)
end

# GOOD — explicit coordination
def disburse!
  update!(status: :disbursed, disbursed_at: Time.current)
  events << LoanDisbursed.new(loan_id: id)
end
```

## 3.2 Method Size

Soft limit: **10 lines per method**. Hard limit: **20 lines**.

If a method exceeds this, extract. Even if the extraction seems trivial. Extracted methods have names. Names are documentation.

```ruby
# GOOD — each method is small and named
def disburse!
  validate_funding_available!
  transition_to_disbursed!
  emit_disbursement_event
end

private

def validate_funding_available!
  raise InsufficientFundsError unless fund.sufficient_for?(principal)
end

def transition_to_disbursed!
  update!(status: :disbursed, disbursed_at: Time.current)
end

def emit_disbursement_event
  events << LoanDisbursed.new(loan_id: id, amount: principal)
end
```

## 3.3 Method Arguments

**Limit: 2 keyword arguments per method.** If you need more, the method is doing too much or should take a parameter object.

```ruby
# BAD — 4 arguments
def calculate_interest(principal, rate, days, compounding)

# GOOD — parameter object or keyword arguments
def calculate_interest(principal:, rate:, days:, compounding:)
```

---

# 4. Naming

## 4.1 Domain Language Only

Names are the most important documentation you will ever write.

**Good:**

* `approve_application`
* `disburse_loan`
* `record_repayment`
* `calculate_interest`
* `assess_penalties`

**Bad:**

* `process`
* `handle`
* `execute`
* `do_work`
* `run`
* `perform_action`

A name like `process` tells you nothing. A name like `disburse_loan` tells you exactly what happens. Every time someone has to read the implementation to understand what a method does, your naming has failed them.

## 4.2 Avoid Generic Suffixes

| Avoid | Use Instead |
|-------|-------------|
| `LoanManager` | `Loan` (put the behavior on the object) |
| `PaymentProcessor` | `Payment` or `ProcessPaymentService` |
| `Helper` | A named module or concern |
| `Utility` | A class with a real business name |
| `Base` | A module with a real concept name |

## 4.3 Boolean Methods

Boolean methods must end in `?`. Always. No exceptions.

```ruby
def disbursed?
  status == "disbursed"
end

def eligible_for_penalty?
  overdue? && days_overdue >= 15
end
```

## 4.4 Bang Methods

Bang methods (`!`) indicate one of two things:

1. The method mutates state (e.g., `loan.disburse!`)
2. The method will raise on failure (e.g., `save!`)

Every bang method should have a corresponding non-bang version that returns a boolean or nil. If it does not make sense to have a non-bang version, the bang is probably unnecessary.

```ruby
def disburse!
  raise InvalidTransitionError unless can_disburse?
  update!(status: :disbursed, disbursed_at: Time.current)
end

def disburse
  return false unless can_disburse?
  update(status: :disbursed, disbursed_at: Time.current)
end
```

---

# 5. Rails Architecture

## 5.1 Controllers

Controllers MUST only:

* authenticate the user
* authorize the action
* parse and validate params
* load domain objects
* call one domain method
* render a response

Controllers MUST NOT contain:

* business logic
* financial calculations
* state transitions
* complex conditionals
* database queries beyond the initial object load

```ruby
# GOOD
class LoanDisbursementsController < ApplicationController
  def create
    loan = Loan.find(params[:loan_id])
    authorize loan, :disburse?

    loan.disburse!

    render json: loan, status: :ok
  end
end

# BAD
class LoanDisbursementsController < ApplicationController
  def create
    loan = Loan.find(params[:loan_id])
    if loan.approved? && current_user.treasurer?
      loan.update(status: :disbursed, disbursed_at: Time.current)
      Transaction.create!(...)  # business logic in controller!
      render json: loan
    end
  end
end
```

**Target: 50 lines or fewer.** Any controller exceeding this is doing something that does not belong in a controller.

## 5.2 Models

Models contain:

* business rules
* state transitions
* validations
* associations
* domain behavior

Models do NOT:

* call external APIs
* perform background jobs directly (enqueue them, do not execute them)
* handle HTTP concerns
* cross aggregate boundaries to modify other models

```ruby
# GOOD
class Loan < ApplicationRecord
  belongs_to :member
  belongs_to :loan_product
  has_many :repayments

  validates :principal, presence: true, numericality: { greater_than: 0 }

  def disburse!
    raise InvalidTransitionError unless approved?
    update!(status: :disbursed, disbursed_at: Time.current)
  end
end
```

---

# 6. Service Objects (Strict Rules)

## 6.1 Last Resort Pattern

Service objects are NOT the default pattern. They are an escape hatch for coordination across aggregate boundaries.

**Do NOT create a service object unless:**

* multiple aggregates need to be coordinated
* an external system integration is required
* no existing domain object clearly owns the behavior

If you can move the behavior onto a model, a value object, or a policy, do that instead.

## 6.2 Naming

Service objects must be named as `VerbNounService`:

```ruby
class DisburseLoanService
class SyncPaymentGatewayService
class GenerateRepaymentScheduleService
```

**Bad names:**

* `LoanService` — what about loans?
* `PaymentService` — what about payments?
* `Processor`, `Manager`, `Handler` — these tell you nothing

## 6.3 Structure

Every service object follows the same structure:

```ruby
class DisburseLoanService
  def self.call(...)
    new(...).call
  end

  def initialize(...)
    @... = ...
  end

  def call
    # orchestration logic only — no domain decisions
  end

  private

  attr_reader :...
end
```

Rules:
* Stateless — all dependencies are injected
* One public method: `call`
* No intermediate state stored on the service
* No domain logic — only coordination

---

# 7. Value Objects

Value objects are the workhorses of a well-designed system. They make implicit concepts explicit.

```ruby
class Money
  include Comparable

  attr_reader :amount, :currency

  def initialize(amount, currency = "PHP")
    @amount = amount
    @currency = currency
  end

  def +(other)
    raise CurrencyMismatchError unless currency == other.currency
    Money.new(amount + other.amount, currency)
  end

  def *(multiplier)
    Money.new((amount * multiplier).round, currency)
  end

  def <=>(other)
    amount <=> other.amount
  end

  def to_s
    format("%.2f %s", amount / 100.0, currency)
  end
end
```

**Rules:**
* Immutable — once created, never changes
* Self-validating — enforce invariants at construction
* No ActiveRecord inheritance — value objects do not persist themselves
* No side effects — pure inputs to pure outputs

---

# 8. Domain Objects

Domain objects:

* represent business concepts, not database tables
* contain behavior, not just data accessors
* must be named after real-world business terms

```ruby
# This is a domain object
class Loan
  def disburse!; end
  def apply_repayment!(amount); end
  def mark_overdue!; end
  def restructure!(new_terms); end
end

# This is NOT a domain object
class LoanReportQuery
  # a query object is infrastructure, not domain
end
```

Every domain object should answer the question: "What can this thing do?" If the answer is "nothing," it is not a domain object — it is a data structure.

---

# 9. ActiveRecord Rules

## 9.1 Keep ActiveRecord Thin (But Not Empty)

Allowed on models:

* validations
* associations
* scopes (simple only)
* domain methods that operate on the model's own data
* callbacks that do NOT trigger cross-aggregate side effects

Not allowed on models:

* API calls
* external integrations
* background job orchestration
* cross-aggregate logic
* business logic that belongs in a value object

## 9.2 Scopes

Scopes must be simple and composable.

```ruby
# GOOD
scope :active, -> { where(status: :active) }
scope :overdue, -> { where("next_due_date < ?", Date.today) }
scope :by_member, ->(member) { where(member: member) }

# BAD — too complex for a scope
scope :portfolio_report, -> {
  joins(:member, :loan_product)
    .where(...)
    .group(...)
    .having(...)
    .select(...)
}
```

Complex queries belong in query objects.

---

# 10. Error Handling

## 10.1 Explicit Domain Exceptions

Domain failures must use explicit exception classes.

```ruby
class InsufficientFundsError < StandardError; end
class LoanNotEligibleError < StandardError; end
class RepaymentAllocationError < StandardError; end
class InvalidTransitionError < StandardError; end
class CurrencyMismatchError < StandardError; end
```

## 10.2 Never Silently Rescue

Do NOT rescue and swallow errors.

```ruby
# BAD — swallowed error
begin
  loan.disburse!
rescue StandardError
  # nothing
end

# GOOD — let it propagate
loan.disburse!

# GOOD — rescue, log, and re-raise or handle explicitly
begin
  loan.disburse!
rescue InvalidTransitionError => e
  Rails.logger.error("Disbursal failed: #{e.message}")
  render json: { error: e.message }, status: :unprocessable_entity
end
```

---

# 11. State Management

State transitions must be explicit methods. You do not set states. You transition to them.

```ruby
# GOOD
loan.approve!
loan.disburse!
loan.mark_overdue!
loan.close!

# BAD — setting state directly
loan.status = "approved"
loan.save
```

Explicit transition methods are where guards live, invariants are checked, and events are emitted. Setting a column directly bypasses all of that.

---

# 12. Background Jobs

Jobs must be:

* **Idempotent** — running the same job twice must be safe
* **Retry-safe** — retries do not change the outcome
* **Logic-free** — domain logic belongs in domain objects, not jobs

```ruby
# GOOD
class SendDisbursementNotificationJob
  def perform(loan_id)
    loan = Loan.find(loan_id)
    MemberNotifier.disbursement(loan.member, loan)
  end
end

# BAD — domain logic in a job
class ProcessDisbursementJob
  def perform(loan_id)
    loan = Loan.find(loan_id)
    ApplicationRecord.transaction do
      loan.update!(status: :disbursed)  # business logic in a job!
      Transaction.create!(...)           # business logic in a job!
    end
  end
end
```

---

# 13. External APIs

All external systems must be wrapped in adapter classes.

```ruby
class PixGateway
  def self.transfer(account:, amount:)
    # ...
  end
end

class SmsGateway
  def self.send(recipient:, message:)
    # ...
  end
end
```

Never call HTTP directly from models, controllers, or jobs. Adapters centralize error handling, retry logic, and timeout management.

---

# 14. Thread Safety

We use a single-server deployment (Kamal), but threads can still interact within a single process.

Rules:

* Do NOT use global state (class variables, global variables)
* Do NOT use `$redis` directly — use connection pools
* Do NOT cache mutable objects in class variables
* Do NOT assume a single-threaded execution model

---

# 15. Testing Standards

## 15.1 Test Behavior, Not Implementation

A test should break only when behavior changes. If it breaks on refactoring, it is testing implementation.

## 15.2 Required Test Types

* **Model specs** — domain logic, state transitions, calculations
* **Request specs** — API contracts, status codes, authorization
* **System specs** — critical user journeys (end-to-end)

## 15.3 Anti-Patterns

* Mocking internal domain objects (test the real thing)
* Testing private methods (test through the public interface)
* Testing Rails framework behavior (Rails tests itself)
* Tests that pass for the wrong reason (false positives are worse than no tests)

---

# 16. Logging

Log business events, not method calls.

```ruby
# GOOD
logger.info "Repayment ##{repayment.id} applied to Loan ##{loan.id}: #{distribution}"

# BAD
logger.debug "Entering apply_repayment method"
logger.debug "Processing..."
logger.debug "Done processing"
```

Every log entry should tell a business story. If a log entry cannot be understood by an accountant, it is noise.

---

# 17. Polymorphism

Avoid polymorphic associations unless absolutely necessary.

Before using polymorphism, evaluate in order:

1. **Separate tables** — the most explicit option
2. **STI** — if models share behavior and schema
3. **Composition** — if the shared behavior can be extracted
4. **Polymorphic association** — only if the first three do not work

---

# 18. Anti-Patterns (STRICTLY FORBIDDEN)

* **God services** — service objects that coordinate everything and own nothing
* **Service objects as default pattern** — the default should be the domain object
* **Business logic in controllers** — controllers route, they do not decide
* **Hidden callbacks** — callbacks that trigger side effects across aggregate boundaries
* **Deep inheritance chains** — three levels max, prefer composition
* **Generic names** — `Manager`, `Handler`, `Processor`, `Utility`, `Helper`
* **Cross-domain model mutations** — Loan does not modify Member records directly
* **Fat scopes with business logic** — scopes are filters, not calculations
* **Silent error swallowing** — every rescue must either handle or re-raise
* **Mocks of domain objects** — test the real thing or redesign

---

# 19. Code Review Checklist

Before considering code complete:

* Does this reflect domain language? (Can an accountant read it?)
* Is business logic in the correct layer? (Not in controllers, views, or jobs)
* Is the code testable? (Can you test it without mocking?)
* Is naming explicit and meaningful? (Does it tell you what it does?)
* Are aggregate boundaries respected? (No cross-aggregate mutations)
* Are side effects isolated? (No hidden callbacks, no implicit state changes)
* Is there unnecessary abstraction? (Could this be simpler?)

If any answer is "no," the code is not done.

---

# 20. Final Rule

> If a piece of code cannot be explained in simple business language, it is too complex. Refactor until it can.

This is the test. Read your code out loud. If it sounds like a technical description of what the computer does, rewrite it. If it sounds like a description of what the business does, you are done.
