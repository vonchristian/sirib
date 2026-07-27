# Authorization Audit & Roadmap

> Audit date: July 2026

---

## Current State

The application has two authorization mechanisms:

1. **`require_permission!`** — used in `Management::BaseController`, checks `Current.user.has_permission?(action, subject)` against `RolePermission` / `Permission` records
2. **`require_authentication`** — used in `ApplicationController`, checks `Current.session` exists
3. **Ad-hoc role checks** — scattered `treasurer?`, `officer?` method checks in individual controllers

---

## Critical Gaps

### 1. 25 Management Controllers Missing `require_permission!`

These controllers inherit from `Management::BaseController` but do NOT call `require_permission!`:

| Controller | File | Mutable Actions |
|------------|------|-----------------|
| `Management::BranchesController` | `app/controllers/management/branches_controller.rb` | create, update, destroy |
| `Management::RolesController` | `app/controllers/management/roles_controller.rb` | create, update, destroy |
| `Management::PoliciesController` | `app/controllers/management/policies_controller.rb` | create, update, activate, deactivate |
| `Management::ApprovalWorkflowsController` | `app/controllers/management/approval_workflows_controller.rb` | create, update |
| `Management::ConfigurationsController` | `app/controllers/management/configurations_controller.rb` | create, approve, activate |
| `Management::EntryTemplatesController` | `app/controllers/management/entry_templates_controller.rb` | create, update, execute |
| `Management::HolidaysController` | `app/controllers/management/holidays_controller.rb` | create, update, destroy |
| `Management::TeamsController` | — | CRUD |
| `Management::DepartmentsController` | — | CRUD |
| `Management::PasswordPoliciesController` | — | create, update |
| `Management::UsersController` | — | create, update, deactivate |
| `Management::UserRoleAssignmentsController` | — | create, destroy |
| `Management::SettingsController` | — | update |
| `Management::DashboardController` | — | (read-only, lower risk) |

**Fix:** Add `before_action :require_permission!` with appropriate `action:` and `subject:` for each.

### 2. No Authorization on Financial Controllers

These controllers DO NOT inherit from `Management::BaseController` and have ZERO authorization:

| Controller | Mutable Actions |
|------------|----------------|
| `Treasury::SavingsAccountsController` | deposit, withdraw, create |
| `Treasury::DepositsController` | create |
| `Treasury::VaultTransfersController` | request, approve |
| `Treasury::LoansController` | disburse |
| `Treasury::CashSessionsController` | open, close |
| `Treasury::SavingsProductsController` | create, update |
| `Equity::AccountsController` | purchase shares |
| `Equity::ProductsController` | create, update |
| `Lending::LoansController` | create, update |
| `Loans::ApplicationsController` | submit, approve, reject |
| `Loans::PaymentsController` | create |
| `Loans::ProductsController` | create, update |
| `Loans::RestructuresController` | approve, reject |
| `MembersController` | deactivate, toggle_portal_access |
| `MemberTransactionsController` | create |
| `Accounting::EntriesController` | create |
| `Accounting::JournalEntriesController` | reverse |

**Fix:** Create a `FinancialBaseController < ApplicationController` that:
- Includes `require_permission!`
- Auto-scopes queries by `Current.branch`
- All financial controllers inherit from it

### 3. No Branch-Level Data Isolation

`Current.branch` is set in `ApplicationController#set_current_branch` from the user's role assignments, but NO financial controller scopes queries by branch:

```ruby
# Current behavior — returns ALL branches' data
Treasury::SavingsAccount.includes(:savings_product).by_latest
Equity::Account.includes(:member, :share_product).by_latest
Lending::Loan.includes(:member, :loan_product)
Membership::Member.order(created_at: :desc)
```

**Impact:** Any authenticated user can view all members, accounts, loans, and transactions across all branches.

**Fix:**
- Add `by_branch` scope to financial models
- Add `before_action :scope_by_branch` in `FinancialBaseController`
- Ensure listing queries filter by `Current.branch`

### 4. Inconsistent Ad-Hoc Role Checks

**File:** `app/controllers/treasury/vault_transfers_controller.rb:37-41`

```ruby
def require_treasurer
  unless Current.user&.treasurer?
    redirect_to treasury_cash_sessions_path, alert: "Only treasurers can manage vault transfers."
  end
end
```

This bypasses the application's `require_permission!` system.

**Fix:** Replace with `require_permission!(action: :manage, subject: :vault_transfer)`.

---

## Remediation Plan

### Phase 1: Add `require_permission!` to All Management Controllers

For each controller:
1. Determine the permission subject (e.g., `:branch`, `:role`, `:policy`)
2. Add `before_action :require_permission!` with `action:` and `subject:`
3. Add request spec verifying permitted user gets 200, unpermitted gets 302

### Phase 2: Create `FinancialBaseController`

```ruby
class FinancialBaseController < ApplicationController
  before_action :require_authentication
  before_action :require_financial_permission
  before_action :scope_by_branch

  private

  def require_financial_permission
    # Map controller_name + action_name to permission subject/action
    # Or require explicit declaration in subclass
  end

  def scope_by_branch
    # Set default_scope or pass Current.branch to queries
  end
end
```

### Phase 3: Migrate Financial Controllers

Make all treasury, equity, lending, and accounting controllers inherit from `FinancialBaseController`.

### Phase 4: Remove Ad-Hoc Role Checks

Replace `treasurer?`, `officer?` checks with `require_permission!`.

### Phase 5: Authorization Tests

Every controller action that mutates data needs:
- Request spec for authorized access
- Request spec for unauthorized access (redirect/403)
- Request spec for cross-branch access (rejected)

---

## Permission Subjects (Proposed)

| Subject | Controllers |
|---------|-------------|
| `:branch` | `Management::BranchesController` |
| `:role` | `Management::RolesController` |
| `:policy` | `Management::PoliciesController` |
| `:approval_workflow` | `Management::ApprovalWorkflowsController` |
| `:configuration` | `Management::ConfigurationsController` |
| `:entry_template` | `Management::EntryTemplatesController` |
| `:holiday` | `Management::HolidaysController` |
| `:user` | `Management::UsersController` |
| `:savings_account` | `Treasury::SavingsAccountsController` |
| `:vault_transfer` | `Treasury::VaultTransfersController` |
| `:cash_session` | `Treasury::CashSessionsController` |
| `:loan_disbursement` | `Treasury::LoansController`, `Lending::LoansController` |
| `:equity_account` | `Equity::AccountsController` |
| `:member` | `MembersController` |
| `:journal_entry` | `Accounting::EntriesController` |
