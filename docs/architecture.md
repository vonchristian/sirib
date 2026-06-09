# Architecture Principles

> Correctness over cleverness. Maintainability over brevity. Simplicity over abstraction.

---

## Mission

This project is a long-term platform for Cooperative Banking and Payments. It will outlast any single developer, survive every audit, and never lose a penny.

Every design decision optimizes for a codebase that is understandable five years from now. Not by its original authors. By someone who has never seen it before.

**The primary goals:**

* Correctness over cleverness
* Maintainability over brevity
* Explicitness over magic
* Business language over technical language
* Simplicity over abstraction
* Incremental evolution over rewrites

---

# 1. Rails Architecture: Omakase

Rails is a full-stack framework with strong opinions. Trust them.

**Follow Rails conventions:**

* RESTful resources — let the HTTP verb + path tell you what the action does
* Conventional naming — `Loan`, `loans_controller.rb`, `loans/` directory structure
* Conventional directories — models in `app/models/`, controllers in `app/controllers/`
* MVC boundaries — models own data and logic, controllers own request handling, views own presentation

**Do not fight Rails:**

If you find yourself writing extensive boilerplate to work around a Rails convention, pause. Rails is not a library you happen to use. It is the architectural substrate of the system. Fighting it means fighting the framework's fifteen years of accumulated knowledge about what works.

Do not introduce abstractions that duplicate what Rails already provides. Callbacks have their place. `before_action` is fine. `scope` blocks are fine. The goal is not to avoid Rails features. The goal is to use them intentionally.

---

# 2. Domain-Driven Design

Business concepts become objects. Not database tables dressed as objects — real objects with behavior, rules, and decisions.

**Good names (business concepts):**

* `Loan` — a financial agreement
* `LoanProduct` — the rules for a type of loan
* `RepaymentSchedule` — the plan of expected payments
* `Collateral` — an asset pledged against a loan
* `RiskAssessment` — an evaluation of borrower risk
* `CashSession` — a teller's daily operations

**Bad names (technical abstractions):**

* `LoanService` — what kind of service? for what?
* `LoanHelper` — helping with what?
* `LoanManager` — manages what aspect?
* `LoanProcessor` — processing what, exactly?
* `LoanUtility` — this name means nothing

A name like `LoanProcessor` tells you nothing about what the object does. A name like `DisburseLoanService` tells you exactly what it does. But even that should be rare — most behavior belongs on the domain object itself.

---

# 3. Object Design

## 3.1 Single Responsibility

Every object has one reason to change. If you cannot describe what an object does in a sentence without using "and," it has too many responsibilities.

```ruby
# BAD — "generates schedules AND calculates penalties AND sends notifications"
class Loan
  def generate_schedule; end
  def calculate_penalty; end
  def notify_member; end
end

# GOOD — "manages the loan lifecycle"
class Loan
  def disburse!; end
  def apply_repayment!; end
  def mark_overdue!; end
end
```

## 3.2 Small Objects

Objects should be small enough to hold in your head. As a rule of thumb:

* Classes should fit on a single screen (~50 lines of meaningful code)
* Methods should do one thing (~5-10 lines)
* Objects should have 5-7 public methods at most

If an object grows beyond this, extract. Extract into value objects, into policies, into query objects. Do not let an object grow into a god.

## 3.3 Composition Over Inheritance

Inheritance is coupling. It is the tightest form of coupling the language provides. A subclass knows everything about its parent class. A change to the parent ripples through every subclass.

Prefer composition:

```ruby
# BAD — deep inheritance
class Loan < ApplicationRecord
end

class AgriculturalLoan < Loan
end

class EmergencyLoan < AgriculturalLoan
end

# GOOD — composition with LoanProduct
class Loan < ApplicationRecord
  belongs_to :loan_product
  delegate :interest_rate, :fee_structure, to: :loan_product
end
```

## 3.4 Design for Change

> The purpose of design is to manage dependencies. Every dependency is a coupling you will have to manage. Every abstraction is a concept you will have to maintain.

When you choose to depend on something, choose carefully. Depend on abstractions, not concrete implementations. Depend on messages, not objects. Depend on behavior, not data.

A well-designed object asks for what it needs (dependency injection) rather than reaching into the system to find it.

```ruby
# BAD — reaches into the system
class Loan
  def disburse!
    PaymentGateway.new.charge!(member, amount)
  end
end

# GOOD — receives what it needs
class Loan
  def disburse!(payment_gateway:)
    payment_gateway.charge!(member, amount)
  end
end
```

---

# 4. Controllers

Controllers are routers, not decision-makers. They do not contain business rules.

A controller should:

1. Authorize the request
2. Parse and validate input
3. Load the relevant domain objects
4. Invoke domain behavior (a single method call)
5. Render a response

```ruby
# GOOD
class LoansController < ApplicationController
  def create
    application = LoanApplication.find(params[:application_id])
    authorize application

    loan = application.approve!(approved_by: current_user)

    render json: loan, status: :created
  end
end

# BAD — business logic in controller
class LoansController < ApplicationController
  def create
    application = LoanApplication.find(params[:application_id])
    if application.member.credit_score > 700 && application.amount < 1_000_000
      loan = Loan.create!(...)  # NO
      render json: loan
    end
  end
end
```

**Target:** 50 lines or fewer. If a controller is larger, it is doing too much.

---

# 5. Models

Models own business behavior. The question a model answers is:

> What can this thing *do*?

Not:

> What can we *do* to this thing?

```ruby
# GOOD — model has agency
loan.disburse!
loan.apply_repayment!(amount)
loan.mark_overdue!

# BAD — external actor manipulates model
LoanDisburser.call(loan)
RepaymentApplier.call(loan, amount)
```

When you put behavior on the model, it is easy to find, easy to change, and easy to test. When you scatter behavior across service objects, it is hidden behind indirection.

---

# 6. Service Objects (Last Resort)

Do NOT create service objects by default. They are not the default architectural pattern. They are an escape hatch.

Before creating a service object, ask: can this behavior belong to:

* the model itself?
* a value object?
* a policy object?
* the aggregate root?
* a query object?

Only create a service object when you need to coordinate multiple aggregates or external systems. A service object is a coordinator, not a logic container.

```ruby
# ACCEPTABLE — coordinates across boundaries
class DisburseLoanService
  def self.call(loan, payment_gateway:)
    new(loan, payment_gateway).call
  end

  def initialize(loan, payment_gateway)
    @loan = loan
    @payment_gateway = payment_gateway
  end

  def call
    ApplicationRecord.transaction do
      @loan.disburse!
      @payment_gateway.enqueue_transfer(@loan.member, @loan.principal)
      LedgerEntry.create!(loan: @loan, type: :disbursement, amount: @loan.principal)
    end
  end
end
```

Service objects must be:
* Stateless — they receive everything they need as arguments
* Named as `VerbNounService` — `DisburseLoanService`, `SyncPaymentGatewayService`
* Have one public method — `call`

---

# 7. Value Objects

Value objects are the safest place for logic. They have no database, no side effects, no collaborators — just inputs and outputs.

Value objects are:

* **Immutable** — once created, they never change
* **Self-validating** — they enforce their own invariants at creation
* **Behavior-rich** — they contain the logic that operates on their data

```ruby
class Money
  include Comparable

  attr_reader :amount, :currency

  def initialize(amount, currency = "PHP")
    raise ArgumentError, "amount must be an integer representing centavos" unless amount.is_a?(Integer)
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
end
```

Examples of value objects in this system:

* `Money` — financial amounts with currency
* `InterestRate` — rate calculations, APR conversions
* `DateRange` — date intervals with business methods
* `RiskScore` — score, grade, factors
* `Percentage` — percentage values with arithmetic
* `Address` — structured location data

---

# 8. Policy Objects

Authorization belongs in policy objects, not scattered across controllers.

```ruby
class LoanPolicy
  def initialize(user, loan)
    @user = user
    @loan = loan
  end

  def approve?
    @user.officer? && @loan.pending_approval?
  end

  def disburse?
    @user.treasurer? && @loan.approved?
  end
end
```

---

# 9. Query Objects

Complex data retrieval belongs in query objects, not in controller-scattered scopes.

```ruby
class DelinquencyReport
  def self.call(as_of: Date.today)
    Loan
      .active
      .where("next_due_date < ?", as_of)
      .includes(:member, :repayment_schedule)
      .order(delinquency_days: :desc)
  end
end
```

If a scope chain spans more than three lines, extract it into a query object.

---

# 10. Calculation Objects

Business calculations — interest, penalties, amortization, risk scores — belong in dedicated calculation objects. Not in models. Not in controllers. Not scattered across helpers.

```ruby
class AmortizationCalculator
  def self.call(principal:, rate:, term_months:)
    # ...
  end
end

class InterestCalculator
  def self.daily_accrual(principal:, annual_rate:, days:)
    # ...
  end
end

class PenaltyCalculator
  def self.for_overdue(loan:, days_overdue:)
    # ...
  end
end

class RiskScoreCalculator
  def self.call(member:, loan:)
    # ...
  end
end
```

---

# 11. Risk Scoring

Risk scoring must be deterministic. Same input, same output, every time. It is not a guess. It is a calculation.

A risk score MUST produce:

```ruby
{
  score: 84,
  grade: "A",
  reasons: [
    "High repayment history",
    "Low delinquency rate",
    "Sufficient collateral coverage"
  ]
}
```

Never return only a number. A number without explanation is a decision that cannot be reviewed, challenged, or understood.

---

# 12. Money

> Never use Float for money. Ever. There is no justification.

Money is a value object with:

* amount stored as integer (centavos/satoshis/sentimos)
* currency code (ISO 4217)
* arithmetic operations that are explicit about precision and rounding

---

# 13. Dates and Time

Business dates are not generic timestamps. Every date field must have a business name:

* `due_date` — when a payment is expected
* `effective_date` — when a rate or term takes effect
* `maturity_date` — when a loan is fully due
* `disbursed_at` — when funds were released
* `posted_at` — when a transaction was recorded

Ambiguous names like `date_1`, `date_2`, or `date` are forbidden. If a date does not have a business meaning, it does not belong on the object.

---

# 14. Events

Business events must be explicit domain objects, not string columns or generic payloads.

**Good:**

* `LoanDisbursed`
* `RepaymentReceived`
* `LoanOverdue`
* `CollateralReleased`
* `LoanClosed`

**Bad:**

* `StatusChanged`
* `Event` (generic)
* `WebhookPayload`
* `Notification`

Events are facts. Facts are immutable, append-only, and auditable.

---

# 15. Polymorphic Associations

Avoid them.

Before using a polymorphic association, explain:

1. Why STI will not work
2. Why separate tables will not work
3. Why composition will not work

Polymorphic associations hide the nature of the relationship from the schema. They make queries harder to optimize, indexes harder to create, and constraints harder to enforce.

---

# 16. Callbacks

Avoid callbacks that trigger business logic.

Callbacks are hidden code paths. They execute at unexpected times. They create implicit dependencies that are invisible to the developer reading the model.

```ruby
# BAD — hidden business logic
class Loan
  after_save :notify_member, if: :disbursed?
  after_save :assess_penalties, if: :overdue?
end

# GOOD — explicit methods
class Loan
  def disburse!
    # change state
    events << LoanDisbursed.new(loan_id: id)
  end

  def mark_overdue!
    # change state
    events << LoanOverdue.new(loan_id: id)
  end
end
```

The rule: if a callback triggers a side effect that matters to the business, it should be an explicit method call.

---

# 17. Background Jobs

Background jobs should only:

* call external APIs
* send notifications (email, SMS)
* process asynchronous work

Business rules must remain in domain objects. A background job is a delivery mechanism, not a decision-maker.

```ruby
# GOOD
class SendDisbursementNotificationJob
  def perform(loan_id)
    loan = Loan.find(loan_id)
    MemberNotifier.disbursement(loan.member, loan)
  end
end
```

---

# 18. Database Transactions

Use database transactions when updating multiple related records.

**Rules:**

* Keep transactions small — they should cover one business operation, not the entire request lifecycle
* Never perform HTTP calls inside a transaction — the transaction holds a connection open, and HTTP is unpredictable
* Never perform external service calls inside a transaction — rollback cannot undo a sent email

---

# 19. External APIs

Wrap every external API with an adapter.

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

Never call third-party APIs directly from controllers or models. Adapters isolate failures, centralize error handling, and make testing possible without network calls.

---

# 20. Naming

Names should reflect the business, not the implementation.

**Prefer:**

* `RepaymentSchedule` — over `LoanScheduleData`
* `DueDate` — over `DatePaymentDue`
* `LoanStatus` — over `StatusCode`

**Avoid:**

* `Helper` — help with what?
* `Manager` — manage what?
* `Processor` — process what?
* `Utility` — utility for what?
* `Stuff`, `Thing`, `Misc` — these names mean nothing

A name should tell you what something is without reading its implementation. If you have to read the code to understand what a class does, rename it.

---

# 21. Logging

Log business events, not technical steps.

```ruby
# GOOD
logger.info "Loan ##{loan.id} disbursed — #{loan.principal} to #{loan.member.name}"

# BAD
logger.info "Processing disbursement for loan id #{loan.id}"
logger.info "Method disburse entered"
logger.info "Process completed"
```

If a log entry does not tell a business story, it is noise.

---

# 22. The Design Feedback Loop

Your architecture is telling you something. Listen.

| If you find yourself... | Your design might need... |
|--------------------------|--------------------------|
| Writing many service objects | Behavior that belongs on the model |
| Fat controllers | Logic that belongs in the model or a policy |
| God models | Extraction into value objects or aggregates |
| Deep inheritance trees | Composition over inheritance |
| Heavy callbacks | Explicit state transition methods |
| Polymorphic associations | Separate tables or STI |
| Complex scopes | A dedicated query object |
| Tests that are hard to set up | An aggregate boundary that is wrong |

---

# 23. Definition of Done

A task is complete only if:

* The business problem is solved in domain language
* The code follows the architecture (correct layer, correct boundaries)
* Tests pass and cover the behavior (not the implementation)
* Naming is clear to someone who knows the business but not the code
* No unnecessary abstraction has been introduced
* Documentation has been updated if the architecture changed
* A future maintainer can understand it without asking the original author

If there is a simpler solution that follows these principles, prefer it. Every line of code you do not write is a line that can never have a bug.

---

# 24. Final Rule

> If a piece of code cannot be explained in simple business language, it is too complex. Refactor until it can.

Simplicity is not about few lines. It is about clarity. A five-line method that is clear is better than a one-liner that requires a comment. Write for the human who will read this in six months. They will thank you.
