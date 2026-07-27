# Database Integrity Audit & Roadmap

> Audit date: July 2026
> Schema version: 32 migrations applied

---

## Schema-Level Issues

### 1. Missing Foreign Keys

Per `database_principles.md`: "Every relationship must enforce referential integrity at the database level."

The following columns lack `add_foreign_key` constraints:

| Table | Column | References | Nullable | Indexed |
|-------|--------|------------|----------|---------|
| `accounting_cash_accounts` | `user_id` | `users(id)` | No | **No** |
| `entries` | `branch_id` | `management_branches(id)` | Yes | Yes |
| `entries` | `created_by_id` | `users(id)` | Yes | Yes |
| `entries` | `reversal_of_id` | `entries(id)` | Yes | Yes |
| `entries` | `template_id` | `entry_templates(id)` | Yes | Yes |
| `entry_templates` | `entry_id` | `entries(id)` | Yes | Yes |
| `entry_template_lines` | `account_id` | `accounts(id)` | No | Yes |

**Migration:** Add foreign keys. For nullable columns use `on_delete: :nullify`. For required columns use `on_delete: :restrict`.

### 2. Missing Indexes on Polymorphic Associations

| Table | Polymorphic Columns | Index Needed |
|-------|--------------------|--------------|
| `management_alerts` | `triggered_by_type` (string), `triggered_by_id` (integer) | `(triggered_by_type, triggered_by_id)` |
| `management_approval_requests` | `requestable_type` (string), `requestable_id` (integer) | `(requestable_type, requestable_id)` |
| `management_audit_logs` | `auditable_type` (string), `auditable_id` (integer) | `(auditable_type, auditable_id)` |
| `management_policies` | `target_entity_type` (string), `target_entity_id` (integer) | `(target_entity_type, target_entity_id)` |

**Migration:** Add composite indexes using `add_index` with `algorithm: :concurrently`.

### 3. Integer vs Bigint Polymorphism

The following use `integer` for polymorphic `_id` columns — risk of overflow:

| Table | Column |
|-------|--------|
| `management_alerts` | `triggered_by_id` |
| `management_approval_requests` | `requestable_id` |
| `management_audit_logs` | `auditable_id` |
| `management_configurations` | `configurable_id` |
| `management_policies` | `target_entity_id` |
| `messaging_messages` | `recipient_id` |
| `treasury_savings_accounts` | `depositor_id` |
| `treasury_time_deposits` | `depositor_id` |
| `treasury_vouchers` | `counterparty_id`, `transactable_id` |

**Migration:** `change_column :table, :column, :bigint` for each.

### 4. `accounts.created_by_id` / `modified_by_id` Type Mismatch

**Schema:** `accounts.created_by_id` and `accounts.modified_by_id` are `uuid` type. All other user-referencing columns use `bigint` matching the `users` table primary key.

These columns cannot have a foreign key to `users` as-is.

**Fix:** Change to `bigint` and add foreign key. Existing data (UUID strings) must be migrated or dropped.

### 5. Stale Nested Set Columns

**Table:** `management_branches`

Contains `parent_id`, `lft`, `rgt`, `depth`, `children_count` — `acts_as_nested_set` columns. But the model only declares:

```ruby
belongs_to :parent, class_name: "Management::Branch", optional: true
```

Missing `acts_as_nested_set` declaration. The `lft`, `rgt`, `depth`, `children_count` columns are never maintained.

**Fix:** Either add `acts_as_nested_set` to the model, or remove the orphan columns.

---

## Model-Level Issues

### 6. Missing Foreign Key Index

**File:** `db/schema.rb:24` — `accounting_cash_accounts.user_id` (bigint, not null, no index)

This column is queried via `User.current_cash_session` and `CashSession.for_today`. Missing index will cause sequential scans at scale.

**Fix:** `add_index :accounting_cash_accounts, :user_id`

### 7. Missing `dependent` on Associations

| Model | Association | Missing `dependent` | Risk |
|-------|-------------|---------------------|------|
| `Accounting::Entry` | `reversal_entries` | None | Orphaned reversal entries |
| `Accounting::Entry` | `reversed_entry` | None | Orphaned entry reference |
| `Management::Branch` | `children` | None | Orphaned child branches |
| `Lending::LoanProduct` | `versions` | None | Orphaned version history |

**Fix:** Add `dependent: :restrict_with_error` or `dependent: :destroy` as appropriate.

### 8. Missing `belongs_to` / `has_many` Declarations

**`Accounting::AmountLine`** — schema has `account_id` (not null), but no `validates :account_id, presence: true`.

**`Equity::Account`** — schema has `opened_by_id` with FK to `users`, but model is missing:
```ruby
belongs_to :opened_by, class_name: "User"
```

**`Cooperative`** — schema implies `has_many` with dozens of tables via `cooperative_id`, but the model declares very few:
```ruby
# Missing:
has_many :entries
has_many :accounts
has_many :loans
has_many :loan_applications
has_many :savings_accounts
# ... and many more
```

**`Membership::Member`** — missing:
```ruby
has_many :equity_accounts
has_many :loan_applications
has_many :loans
```

**`Lending::Loan`** — missing:
```ruby
has_one :loan_aging, dependent: :destroy
```

### 9. Callback Misuse

Per `architecture.md`: "Avoid callbacks that trigger business logic."

| Model | Callback | Problem |
|-------|----------|---------|
| `Management::Approval` | `after_create :update_approval_request_status` | Mutates parent from child model |
| `Equity::Product` | `before_create :auto_create_equity_ledger` | No `throw :abort` if ledger save fails |
| `External::Bank` | `after_create :create_tracking_accounts` | No `throw :abort` on failure |
| `External::BankAccount` | `after_create :create_tracking_accounts, :create_interest_earned_template` | Two callbacks creating records |
| `Lending::LoanProduct` | `before_update :create_version_snapshot` | No `throw :abort` on version save failure |

**Fix:** Move to service objects. Add `throw :abort` where callbacks remain.

### 10. Missing Validations

| Model | Missing Validation |
|-------|-------------------|
| `Access::BackupCode` | `code_digest` presence (schema has `null: false`) |
| `Cooperative` | `status` inclusion (`active`/`inactive`), `locale` inclusion |
| `Management::BranchPerformanceSnapshot` | `metrics` presence (JSONB, `null: false`) |
| `Management::SystemHealthSnapshot` | `status` inclusion (default `"healthy"`) |
| `Accounting::AmountLine` | `account_id` presence (schema has `null: false`) |

### 11. `AppendOnlyOverride` Ignores User

**File:** `app/models/concerns/append_only_override.rb`

```ruby
def self.with_override(reason:, user: nil)
  raise ArgumentError, "reason is required" if reason.blank?
  # user parameter is accepted but never used
  yield
end
```

**Fix:** Log or record the `reason` and `user` who performed the override.

### 12. N+1 Query Patterns

| Model | Method | Issue |
|-------|--------|-------|
| `Equity::Account` | `member_name` | Lazy-loads `member` each call |
| `Equity::Account` | `current_share_value` | Lazy-loads `share_product` each call |
| `Treasury::CashSession` | `total_receipts`, `total_disbursements` | Separate `SUM` queries per voucher type |
| `User` | `has_permission?` | Query per permission check, called repeatedly in listings |

**Fix:** Add `includes(:member)` to scopes, use single `GROUP BY` query for voucher sums, cache permission lookups per request.

---

## Remediation Order

1. Add missing foreign keys (6 migrations)
2. Add composite indexes on polymorphic associations (4 indexes)
3. Fix `accounts.created_by_id` / `modified_by_id` type (uuid → bigint)
4. Add missing `dependent` on associations
5. Add missing model declarations (`belongs_to`, `has_many`)
6. Convert callback-based record creation to services
7. Migrate polymorphic integer IDs to bigint
8. Add missing validation declarations
9. Fix N+1 query patterns

---

## Migration Safety

All migrations should be:
- Reversible (or explicitly marked irreversible with reason)
- Use `CONCURRENTLY` for index creation in production
- Deployed incrementally — add columns before removing old ones
- Tested against a copy of production data before deployment
