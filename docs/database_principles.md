# Database Principles

> The database is not a storage layer. It is the financial truth engine of the cooperative.

---

## Purpose

This document defines the **database design principles** for the Cooperative Banking Platform.

It ensures:

* Financial correctness is never compromised by application bugs
* Data integrity is guaranteed under concurrency — two tellers processing at the same time cannot corrupt state
* Schema evolution is safe and predictable — migrations do not break running systems
* The database reflects real financial truth, not application convenience

The database is the **system of record**, not the application. If the application crashes and loses its in-memory state, the database must still tell you exactly where every penny is.

---

# 1. Core Philosophy

We optimize for:

* **Consistency over performance** (by default) — a fast wrong answer is worse than a slow right one
* **Explicit schema over implicit behavior** — every column tells you what it means
* **Auditable financial history** — every transaction leaves a trail that cannot be erased
* **Append-only financial events** — you never modify a financial record; you add a new one
* **Predictable transactional boundaries** — every operation knows exactly what it guards

We reject:

* Hidden side effects in queries — triggers that modify unrelated tables
* Non-deterministic state updates — updates that depend on order of execution
* Silent data mutations — soft deletes that are invisible to queries
* Schema ambiguity — columns named `type`, `status`, `data` that mean different things in different contexts

---

# 2. Data Classification

Every piece of data in the system belongs to exactly one of three categories. Knowing the category tells you how to handle it.

---

## 2.1 System of Record (SoR)

The canonical truth. These are the records that, if lost, mean the system cannot be reconstructed.

**Examples:**

* Loans
* Transactions
* Repayments
* Ledger entries
* Members
* Collateral records

**Rules:**

* Must never be overwritten destructively — no `UPDATE` that loses prior values
* Changes must be recorded as new events or explicit state transitions with immutable audit trails
* Soft deletes are forbidden — financial records are never deleted

---

## 2.2 Derived Data

Computed from System of Record data. Always reproducible.

**Examples:**

* Risk scores
* Dashboards
* Reports (portfolio summaries, delinquency reports)
* Aggregated statistics
* Cached balances

**Rules:**

* Must be reproducible from the System of Record at any time
* Must not be manually edited — if the source data is wrong, fix the source
* Can be regenerated at any time — if lost, recompute

A risk score is derived data because it is computed from member history and loan data. The underlying data is the truth. The score is a calculation.

---

## 2.3 Reference Data

Static or slowly changing configuration data.

**Examples:**

* Loan products (interest rates, fee structures, term limits)
* Interest rate tables
* Branch information
* User roles and permissions

**Rules:**

* Versioned when changes affect historical meaning — if a loan product changes, old loans still reference the old product definition
* Must have effective dates — "this product changed on this date"

---

# 3. Schema Design Principles

## 3.1 Explicit Columns

Every column must have a clear business meaning and an unambiguous name.

**Bad:**

| Column | Problem |
|--------|---------|
| `status` | Status of what? Which state machine? |
| `type` | Type of what? One of many kinds? |
| `data` | What data? JSON blob? Arbitrary payload? |
| `value` | Value of what? In what unit? |

**Good:**

| Column | Meaning |
|--------|---------|
| `loan_status` | The current state of the loan lifecycle |
| `transaction_type` | The kind of financial event (deposit, withdrawal, disbursement) |
| `repayment_due_date` | The date a repayment is expected |
| `principal_amount_cents` | The principal amount in centavos |

A column name should be self-documenting. If you need to read the comment to understand what a column contains, the name is wrong.

## 3.2 Never Reuse Columns

A column means one thing for the lifetime of the system. Do not repurpose it.

**Bad:**

```ruby
# Column: status
# Currently used for: loan status (pending, approved, disbursed, closed)
# Previously used for: payment status (pending, completed, failed)
# Problem: historical data cannot be interpreted without context
```

If you need a new concept, add a new column. Old data should still be interpretable without a decoder ring.

## 3.3 Prefer Immutable Financial Records

Financial records should NOT be updated in place. Ever.

Instead:

* Insert a new record
* Reference the previous record if needed
* Never `UPDATE` a transaction, a repayment, or a ledger entry

```sql
-- BAD — mutable financial record
UPDATE transactions
SET amount = 1000
WHERE id = 123;

-- GOOD — correcting transaction
INSERT INTO transactions (type, amount, corrected_transaction_id)
VALUES ('adjustment', 1000, 123);
```

Immutability is the foundation of audit. If a record can change, you can never prove what happened.

## 3.4 Soft Deletes

Soft deletes are allowed ONLY for:

* User-facing non-financial data (addresses, phone numbers, notes)
* Configuration data (branches, user accounts)

**Forbidden for:**

* Transactions
* Repayments
* Ledger entries
* Loans
* Any financial record

If a financial record is created in error, you do not delete it. You write a compensating transaction that references the error and corrects it.

---

# 4. Transactions (ACID)

## 4.1 Atomicity Is Not Optional

Every financial operation must be wrapped in a database transaction. If any step fails, the entire operation must roll back.

**Operations that MUST be transactional:**

* Loan disbursement (update loan + create transaction + update balance)
* Repayment application (receive payment + allocate distribution + update balance)
* Account transfer (debit one account + credit another)

```ruby
# GOOD — atomic operation
ApplicationRecord.transaction do
  loan.disburse!
  Transaction.create!(type: :disbursement, amount: loan.principal, loan: loan)
  SavingsAccount.update_balance!(loan.member, -loan.principal)
end
```

## 4.2 No External Calls Inside Transactions

> Never call external APIs inside database transactions.

**Allowed inside a transaction:**
* Database writes
* In-memory computation
* Object state changes

**NOT allowed:**
* HTTP calls
* Payment gateway calls
* SMS or email delivery
* External queue pushes

Why: external calls are unpredictable. They can timeout, hang, or fail slowly. A transaction that waits on an external call holds a database connection open, potentially blocking other operations and causing deadlocks.

If you need to trigger an external call after a transaction succeeds, use callbacks that fire after the transaction commits:

```ruby
# GOOD
ApplicationRecord.transaction do
  loan.disburse!
  Transaction.create!(...)
end

# Now safe to call external services
MemberNotifier.disbursement(loan.member, loan).deliver_later
```

## 4.3 Transaction Scope Must Be Small

Keep transactions focused on a single business operation. Do not wrap the entire request lifecycle in a transaction.

**Bad:**
```ruby
# A controller wrapping everything in one transaction
ApplicationRecord.transaction do
  @loan = Loan.create!(params)
  @member = Member.create!(params)
  @savings_account = SavingsAccount.create!(params)
  # ... more unrelated work
end
```

**Good:**
```ruby
# Each operation has its own small transaction
@loan = Loan.create!(params)
LoanMailer.welcome(@loan).deliver_later
```

## 4.4 Isolation Level

Default: **Read Committed** (PostgreSQL default). This prevents dirty reads while allowing concurrent transactions.

Upgrade to **Serializable** only for high-risk operations where concurrent modification could lead to data corruption:

```ruby
ApplicationRecord.transaction(isolation: :serializable) do
  balance = AccountBalance.find(account_id)
  balance.update!(amount: balance.amount - amount)
end
```

Use serializable sparingly. It has higher overhead and can cause serialization failures under contention. Most operations do not need it.

## 4.5 Race Condition Safety

Financial operations MUST be safe under concurrency.

**Use row-level locking for critical writes:**

```ruby
# Pessimistic lock — for financial operations
Loan.transaction do
  loan = Loan.lock("FOR UPDATE").find(loan_id)
  loan.disburse!
end
```

**Use optimistic locking for low-contention updates:**

```ruby
# Optimistic lock — controlled by lock_version column
loan = Loan.find(loan_id)
loan.disburse! # Raises ActiveRecord::StaleObjectError if another process modified it
```

**Rule of thumb:** if money is at stake, use pessimistic locking. If the cost of a conflict is a retry, optimistic locking is fine.

---

# 5. Ledger and Financial Integrity

## 5.1 Double-Entry Bookkeeping

Every financial movement must be reflected in a double-entry ledger. Every transaction has:

* A debit entry (increase in one account)
* A credit entry (decrease in another account)

The sum of all debits must equal the sum of all credits. Total balance is always zero-sum.

```sql
-- A loan disbursement creates two ledger entries
INSERT INTO ledger_entries (account_id, type, amount, reference_id)
VALUES (cash_account_id, 'credit', 100000, loan_id);

INSERT INTO ledger_entries (account_id, type, amount, reference_id)
VALUES (loan_receivable_id, 'debit', 100000, loan_id);
```

## 5.2 Ledger Is Append-Only

Ledger entries are:

* **Immutable** — once written, never changed
* **Never updated** — a correction is a new entry, not an edit
* **Never deleted** — a reversal is a new entry that references the original

```ruby
# BAD — modifying a ledger entry
entry = LedgerEntry.find(id)
entry.update!(amount: new_amount)

# GOOD — reversal entry
LedgerEntry.create!(
  type: :reversal,
  amount: -original_amount,
  reverses: original_entry,
  reason: "Correction: incorrect amount"
)
```

## 5.3 Source of Truth

If the application state and the ledger disagree:

> Ledger wins.

The ledger is the authoritative record of every financial event. Application state (cached balances, derived values) can be recomputed from the ledger. The ledger cannot be recomputed from application state.

---

# 6. Migration Standards

## 6.1 Migrations Must Be Safe

Every migration must:

* Be reversible (or explicitly marked irreversible with a clear reason)
* Avoid long-running locks where possible (use `CONCURRENTLY` for indexes)
* Be small and incremental — one change per migration

```ruby
class AddDisbursedAtToLoans < ActiveRecord::Migration[7.1]
  def up
    add_column :loans, :disbursed_at, :datetime
  end

  def down
    remove_column :loans, :disbursed_at
  end
end
```

## 6.2 No Business Logic in Migrations

Migrations are for schema changes only. They do not:

* Call models (the model class may not exist in the future)
* Invoke services
* Run business rules
* Transform data (that is a data migration, separate it)

```ruby
# BAD — calling models in a migration
class PopulateDisbursedAt < ActiveRecord::Migration[7.1]
  def up
    Loan.where(status: :disbursed).find_each do |loan|
      loan.update!(disbursed_at: loan.created_at)
    end
  end
end
```

## 6.3 Data Migrations Are Separate

If data needs to be transformed:

1. Create a separate rake task or script in `lib/data_migrations/`
2. Run it outside the deployment window
3. Do NOT mix it with schema migrations

```ruby
# lib/data_migrations/2024/backfill_disbursed_at.rake
namespace :data_migration do
  desc "Backfill disbursed_at for existing disbursed loans"
  task backfill_disbursed_at: :environment do
    Loan.where(status: :disbursed, disbursed_at: nil).find_each do |loan|
      loan.update_column(:disbursed_at, loan.created_at)
    end
  end
end
```

## 6.4 Backward Compatibility

Schema changes must support both old and new code during the deployment window.

**Patterns:**

* Add columns first (old code ignores unknown columns)
* Deploy code that uses new columns
* Remove old columns in a later migration

```ruby
# Step 1: Add new column (deploy first)
add_column :loans, :status_v2, :string

# Step 2: Deploy code that reads/writes both old and new

# Step 3: Remove old column (deploy after code is stable)
remove_column :loans, :status, :string

# Step 4: Rename (if needed)
rename_column :loans, :status_v2, :status
```

## 6.5 Column Removal Process

1. Add new column (or verify no code uses the old column)
2. Deploy code that no longer references the old column
3. Wait for a full deployment cycle to verify
4. Remove the old column in a later migration

---

# 7. Indexing Strategy

## 7.1 Index for Real Queries

Every index must be justified by a real query pattern. Do not index speculatively.

**Identify indexes from:**

* Slow queries in production
* Query patterns in the codebase (lookups by status, member, date range)
* Known access patterns (daily reports, dashboards, reconciliation queries)

## 7.2 Avoid Over-Indexing

Indexes have costs:

* **Slow writes** — every index must be updated on INSERT, UPDATE, DELETE
* **Increased storage** — every index takes disk space
* **Query planner overhead** — too many indexes confuse the optimizer

Only add an index when you have evidence it is needed.

## 7.3 Composite Index Rules

For composite indexes, order matters:

* Put the most selective column first (the one that filters the most rows)
* Put equality conditions before range conditions

```sql
-- GOOD: status is highly selective, due_date is a range filter
CREATE INDEX idx_loans_status_due_date ON loans (status, due_date);

-- BAD: due_date is a range, so status can't use the index efficiently after the range
CREATE INDEX idx_loans_due_date_status ON loans (due_date, status);
```

---

# 8. Performance Principles

## 8.1 Avoid N+1 Queries

Every query pattern must be checked for N+1. Use:

* `includes` for eager loading associations
* `preload` for separate queries per association
* `joins` when you need to filter or aggregate across associations

Add the Bullet gem to the test suite in development to catch N+1 queries automatically.

## 8.2 Move Complex Computation Out of SQL

SQL is not a programming language. Do not write business logic in it.

**Move to application layer:**

* Interest calculations
* Penalty computations
* Risk scoring
* Complex aggregations for non-critical paths

**Keep in SQL:**

* Filtering
* Ordering
* Joins
* Simple aggregations (COUNT, SUM, AVG)

## 8.3 Pagination Is Mandatory

Every endpoint that returns a list MUST paginate.

Never load unbounded datasets. No exception.

```ruby
# GOOD — always paginated
loans = Loan.active
            .includes(:member)
            .order(created_at: :desc)
            .page(params[:page])
            .per(params[:per_page] || 20)
```

---

# 9. Concurrency Rules

## 9.1 Locking Strategy

| Scenario | Strategy |
|----------|----------|
| Financial writes (disbursement, repayment) | Pessimistic locking (`FOR UPDATE`) |
| Low-contention updates (profile changes) | Optimistic locking (`lock_version`) |
| Reporting queries | No locking (read-only) |
| High-risk operations | Serializable isolation |

## 9.2 Idempotency

All financial operations must be idempotent. Running the same operation twice must produce the same result as running it once.

**Techniques:**

* Unique constraints on business identifiers (transaction reference, payment ID)
* Idempotency keys — the caller provides a unique key; the database rejects duplicates

```ruby
# Idempotency through unique constraint
create_table :repayments do |t|
  t.string :external_reference, null: false
  t.index :external_reference, unique: true
end

# Duplicate call raises ActiveRecord::RecordNotUnique, caught cleanly
```

---

# 10. Data Integrity Rules

## 10.1 Foreign Keys Are Required

Every relationship must enforce referential integrity at the database level.

```ruby
# GOOD — database-enforced
create_table :loans do |t|
  t.references :member, null: false, foreign_key: true
end
```

Do NOT disable foreign keys in production. The database is the last line of defense against inconsistent data.

## 10.2 Nullability

Avoid nullable columns unless the field is explicitly optional in the domain.

```ruby
# GOOD — explicit about nullability
t.datetime :disbursed_at, null: true  # null until the loan is disbursed
t.string :member_number, null: false   # always required
```

Prefer explicit empty states over NULL ambiguity:

* `status = ""` vs `status IS NULL` — the empty string says "not set"; NULL says "unknown"
* `amount_cents = 0` vs `amount_cents IS NULL` — zero is a valid amount; NULL is an error

## 10.3 Unique Constraints

Every business identifier must be enforced at the database level with a unique index.

```ruby
add_index :loans, :loan_number, unique: true
add_index :transactions, :reference_id, unique: true
add_index :members, :member_number, unique: true
```

Unique constraints prevent the most insidious class of bugs: the record that was inserted twice.

---

# 11. Money Handling

## 11.1 Never Use Float

Floating-point arithmetic is approximate. Money is not approximate.

**Forbidden:**

* `float` columns for money
* `double precision` columns for money
* Float arithmetic for financial calculations

**Allowed:**

* `decimal(precision, scale)` — e.g., `DECIMAL(18,2)`
* `integer` (cents/satoshis/sentimos) — preferred for simplicity

```ruby
# PREFERRED — integer cents
t.integer :principal_cents, null: false

# ACCEPTABLE — decimal with precision
t.decimal :principal, precision: 18, scale: 2, null: false
```

## 11.2 Currency Awareness

Every monetary value must include its currency code.

```ruby
t.string :currency, null: false, default: "PHP", limit: 3
```

No implicit currency. If you see a monetary value, you know what currency it is in.

## 11.3 Precision

Define scale and precision explicitly for every monetary column.

```ruby
t.decimal :amount, precision: 18, scale: 2, null: false
```

---

# 12. Time Handling

## 12.1 Always UTC

Every timestamp is stored in UTC. No exceptions. Time zone conversion happens in the application, not the database.

```ruby
# `created_at` and `updated_at` are already in UTC
# Application handles timezone display
Time.use_zone("Asia/Manila") do
  render json: { due_date: loan.due_date }
end
```

## 12.2 Business Date Fields

Use explicit, named date fields with business meaning:

* `due_date` — when a payment is expected
* `effective_date` — when a rate or term takes effect
* `posted_at` — when a transaction was recorded
* `disbursed_at` — when funds were released
* `maturity_date` — when a loan is fully due

Avoid `created_at` for business logic. The record creation timestamp is an infrastructure concern. Use explicit business date fields for domain decisions.

---

# 13. Event Sourcing (Lightweight)

We do NOT implement full event sourcing, but we follow its principles:

* Append-only financial events — records are added, never modified
* Domain events for cross-context communication — events are the contract between contexts
* Immutable audit trail — every event is a fact that cannot be erased

Events are:

* **Immutable** — once recorded, never changed
* **Auditable** — every event carries timestamp, source, and reason
* **Replayable** — in principle, the state can be reconstructed from events

---

# 14. Reporting

## 14.1 OLTP vs OLAP Separation

Transactional queries run against the OLTP database (PostgreSQL). Analytical queries belong in a separate OLAP system.

**OLTP (PostgreSQL — current):**
* Transactions
* Loans
* Repayments
* Member lookups

**OLAP (future — ClickHouse or similar):**
* Portfolio analytics
* Trend analysis
* Risk dashboards
* Regulatory reports

Never overload the OLTP database with heavy reporting queries.

---

# 15. Anti-Patterns (STRICTLY FORBIDDEN)

* **Updating financial records in place** — transactions, repayments, and ledger entries are immutable
* **Floating-point money calculations** — `float` and money do not mix
* **Hidden side effects in triggers** — database triggers that modify unrelated tables
* **Business logic in migrations** — migrations change schema; data migrations are separate scripts
* **Cross-domain writes without a transaction boundary** — updating Loans and Members in the same operation without a transaction
* **Silent data loss on delete** — hard-deleting financial records
* **Nullable ambiguity in financial fields** — `NULL` means "missing," not "zero"
* **Unindexed production queries** — every query pattern must be indexed
* **External API calls inside database transactions** — HTTP inside a transaction is a deadlock waiting to happen
* **SELECT * in production code** — always specify the columns you need

---

# 16. Golden Rule

> If a database operation affects money, it must be explicit, transactional, auditable, and irreversible in history.

Every operation on the database should answer:

1. **Explicit** — what exactly is changing?
2. **Transactional** — what happens if this fails halfway?
3. **Auditable** — who will know this happened in five years?
4. **Irreversible** — can this change be undone without losing history?

If any answer is unclear, the operation is not ready for production.

---

# 17. Final Principle

> The database is not a storage layer. It is the financial truth engine of the cooperative system.

Treat it with the respect it deserves. Every schema decision is a commitment to a way of thinking about the domain. Every migration is a change to the truth. Every query is a question you ask the system about what it knows.

Design the schema as carefully as you design the domain model. They are two views of the same truth.
