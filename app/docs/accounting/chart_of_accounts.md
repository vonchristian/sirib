Chart of Accounts UX (Accountant Daily Workflow Focus)
Coop Core Banking Platform (Rails 8)
1. Product Goal

Design a Chart of Accounts interface that accountants use every day to:

Find accounts instantly
Validate postings quickly
Navigate financial structure without confusion
Investigate balances and transactions
Reduce time spent searching or drilling into accounts
2. Core UX Principle

Accountants do NOT think in trees first.
They think in:

account name
account code
transaction behavior
balance anomalies
“where did this go?”

So the system must support:

Search-first navigation
Tree as secondary structure
Context-aware filtering
3. Primary Screen: Chart of Accounts Workbench

This is NOT a static tree page.

It is a financial control dashboard for accounts.

4. Layout Structure
Left Panel: Smart Tree (Ledger Hierarchy)
Uses Ledger ancestry
Expand/collapse nodes
Lazy-loaded children
Shows:
Ledger name
aggregated balance (pre-computed, updated on every EntryLine write)
account count under leaf
Center Panel: Accounts Table (Main Work Area)

This is the MOST USED component.

Columns:

Account Code
Account Name
Ledger Path (breadcrumb)
Type (Asset/Liability/etc)
Balance (cached, event-driven update on write)
Status (Active/Archived)
Posting Allowed (yes/no)

Clicking an account row navigates to the full Account Detail View (Section 9). There is no right-panel inspector.
5. Global Search (Critical Feature)
Search must be instant (<300ms UX target)

Search across:

Account code
Account name
Ledger name
Partial matches
Search behavior

When user types:

"cash"

Returns:

Ledgers:
  Cash and Cash Equivalents
  Cash on Hand
Accounts:
  Cash in Bank - LandBank
  Cash in Bank - PNB
Search result grouping

Grouped by:

Ledgers first (matching ledger names and paths)
Accounts second (matching account code or name)
6. Advanced Filters (Daily Accounting Use)

Filters are ALWAYS visible:

Filter by:
Account Type
Ledger Level (depth)
Posting Allowed (Yes/No)
Status (Active/Archived)
Has Activity (has EntryLines)
Zero Balance accounts
High movement accounts
7. Accountant Workflows Supported
7.1 “Find an account quickly”
type partial name or code
instant results
jump directly to account detail view
7.2 “Verify posting before entry”

Accountants check:

is account active?
is it postable?
correct ledger placement?

System shows warnings:

⚠ archived account
⚠ non-postable account
⚠ rarely used account
7.3 “Investigate balances”

From account view:

total debits
total credits
net balance
last 10 transactions
7.4 “Audit suspicious movements”

Filters:

high-volume accounts
sudden balance spikes
accounts with unusual posting frequency
8. Ledger Tree (Secondary Navigation)

Ledger is NOT primary UX.

It is used for:

structural understanding
reporting grouping
drill-down navigation
Ledger node display shows:
Name
Total balance (rolled up)
Number of accounts under node
Activity indicator (high/low movement)
9. Account Detail View (Deep Focus Mode)

When opened:

Shows 4 sections:

1. Summary
Balance
Ledger path
Status
Posting eligibility
2. Transactions (EntryLines)
sortable
filterable by date
debit/credit split
3. Activity Insights
daily/weekly movement trend
last posting date
frequency indicator
4. Audit Trail
who created account
who modified
structural changes (ledger moves)
10. UX Performance Requirements
Global search: < 300ms perceived response
Tree expand: < 150ms
Account detail load: < 200ms
Filters must be client-reactive where possible
11. Data Display Rules
Always show:
Account code (never hide)
Ledger path (breadcrumb style)
Status indicator
Posting eligibility
Never require:
deep tree navigation before search
manual ledger traversal to find accounts
switching screens for basic lookup
12. System Intelligence (Helpful UX Layer)

System highlights:

Frequently used accounts
Recently posted accounts
Accounts with anomalies
Zero movement accounts (inactive candidates)
13. UX States
Empty state
“Search for an account or ledger”
No results
Suggest similar codes/names
Warning state
invalid posting account highlighted
14. API Requirements
Search API
GET /chart_of_accounts/search?q=

Returns:

ledger matches
account matches
grouped results
Tree API
GET /chart_of_accounts/tree

Returns:

ledger ancestry
aggregated balances
account counts
Account Table API
GET /accounts?filters...
14.5. Data Model (Actual Architecture — verified against app/models/)

The codebase uses TWO separate tables. The STI `accountable_type` pattern described above was a design proposal — do NOT implement it. Build on the existing models.

14.5.1 Multi-Tenancy
All models use `cooperative_id` (not `coop_id`) for tenant isolation. Every query must scope by cooperative_id. Never query any accounting model without a cooperative_id scope.

Existing field on all models: cooperative_id (UUID, FK to Cooperatives, indexed)

14.5.2 Account Model (app/models/accounting/account.rb)
EXISTING fields (keep as-is):
  id: UUID (primary key)
  cooperative_id: UUID (required, FK, indexed)
  ledger_id: UUID (FK to Ledger, nullable — top-level accounts have no parent ledger)
  name: string
  account_code: string (unique per cooperative)
  account_type: enum [asset, equity, liability, revenue, expense]
  contra: boolean (default false) — indicates this account reverses normal debit/credit behavior

NEW fields to add (migration required):
  status: enum [active, archived] — default active
    Add via: add_column :accounts, :status, :string, default: 'active', null: false
    Add index: add_index :accounts, [:cooperative_id, :status]
  postable: boolean — default true
    Add via: add_column :accounts, :postable, :boolean, default: true, null: false
  current_balance_cents: integer — pre-computed cached balance in cents (optional enhancement, see 14.5.6)
    Add via: add_column :accounts, :current_balance_cents, :integer, default: 0, null: false
  created_by_id: UUID (FK to users) — already partially exists via t.references but not enforced
  modified_by_id: UUID (FK to users) — add explicitly

RELATIONSHIP: Account belongs_to :ledger. Account has_many :amount_lines. Account has_many :running_balances.
Account does NOT have ancestry — tree structure is via Ledger's has_ancestry.

14.5.3 Ledger Model (app/models/accounting/ledger.rb)
EXISTING fields (keep as-is):
  id: UUID (primary key)
  cooperative_id: UUID (required, FK, indexed)
  name: string
  account_code: string (unique per cooperative)
  account_type: enum [asset, equity, liability, revenue, expense]
  contra: boolean (default false)
  ancestry: string (nested set via has_ancestry gem, e.g. "1/1-01")

NEW fields to add (migration required):
  current_balance_cents: integer — pre-computed cached balance in cents (optional enhancement)
    Add via: add_column :ledgers, :current_balance_cents, :integer, default: 0, null: false

RELATIONSHIP: Ledger has_ancestry (has_many :accounts). Ledger has_many :running_balances.
Ledger has the has_ancestry gem on line 6 of ledger.rb. Do NOT add ancestry to Account.

14.5.4 AmountLine Model (app/models/accounting/amount_line.rb) — called EntryLine in this doc
EXISTING fields (keep as-is):
  id: UUID (primary key)
  cooperative_id: UUID (required, FK, indexed)
  entry_id: UUID (FK to Entry, required)
  account_id: UUID (FK to Account, required)
  amount_type: enum (debit=0, credit=1) — NOT entry_type
  amount_cents: integer (NOT decimal — uses Money gem for precision)
  amount_currency: string (default "PHP")

No new fields needed. AmountLine is append-only — never update or delete after creation.

14.5.5 Entry Model (app/models/accounting/entry.rb)
EXISTING fields (keep as-is):
  id: UUID (primary key)
  cooperative_id: UUID (required, FK, indexed)
  reference_number: string (auto-generated)
  description: string
  entry_date: date (NOT entry_number) — the date of the transaction
  status: enum [pending, posted, reversed]
  posted_at: timestamp
  created_by_id: UUID (FK to users)
  source_module: string
  entry_type: string

No new fields needed. Entry.groups AmountLines and is the atomic posting unit.

14.5.6 Posting Eligibility Rule
An account accepts AmountLines if and only if:
  status == 'active' AND postable == true

The UI displays warnings (Section 7.2). The PostingEngine or ValidationEngine must enforce this — AmountLines must NOT be created against ineligible accounts.

Implementation: In Accounting::PostingEngine#post! or a dedicated Accounting::AccountStatusService, validate before creating AmountLines:
  account = Account.find(id)
  unless account.status == 'active' && account.postable?
    raise Accounting::AccountNotPostableError, "Account #{account.account_code} is #{account.status} and postable=#{account.postable}"
  end

14.5.7 Balance Computation
CURRENT IMPLEMENTATION: Balance is computed on-demand via Account#balance method:
  AmountLine.joins(:entry).group(:account_id, :amount_type).sum(:amount_cents)
This is correct and should NOT be removed. It is the source of truth.

OPTIONAL ENHANCEMENT (do in a later iteration): Pre-compute current_balance_cents on Account/Ledger and cache it, updated via background job on every AmountLine create. This enables <10ms reads at scale but adds eventual consistency complexity.

Current on-demand approach is sufficient for the initial release. Mark current_balance_cents as: "Deferred — implement only when performance testing shows it is needed."

14.5.8 Audit Trail
The system captures via created_by_id / modified_by_id timestamps:
  Account: created_by_id (set on create), modified_by_id (set on update via ApplicationRecord callback)
  Entry: created_by_id (set on create), posted_by_id (set when status becomes posted)

No separate audit log table exists. The designed audit log table (field_changed, old_value, new_value) is deferred. For now, rely on created_by_id / modified_by_id + entry audit via Entry#source_module tracking.

14.5.9 RunningBalance Model (app/models/accounting/running_balance.rb)
EXISTING fields:
  id: UUID (primary key)
  cooperative_id: UUID (required, FK, indexed)
  account_id: UUID (nullable, FK to Account)
  ledger_id: UUID (nullable, FK to Ledger)
  as_of_date: date
  balance_cents: integer (monetized via monetize :balance_cents)
  balance_currency: string (default "PHP")

This model stores DAILY snapshots of account/ledger balances. The UpdateRunningBalancesJob populates it. The CoA tree panel's aggregated balance uses ledger.balance() (computed) or can be augmented with RunningBalance latest_for_ledger.

No changes needed to this model.

14.5.10 Missing Audit Columns
To add created_by_id and modified_by_id to Account:
  add_column :accounts, :created_by_id, :uuid, null: true
  add_column :accounts, :modified_by_id, :uuid, null: true
  add_index :accounts, :created_by_id
  add_index :accounts, :modified_by_id

Set these via ApplicationRecord callbacks:
  before_validation on: :create do
    self.created_by_id = Current.user.id if defined?(Current) && Current.user
  end
  before_validation on: :update do
    self.modified_by_id = Current.user.id if defined?(Current) && Current.user
  end

15. Frontend Components (Rails 8 + Hotwire)
CoA::TreePanel
CoA::AccountTable
CoA::GlobalSearch
CoA::FilterBar
16. Testing Requirements

16.1 Unit Tests (RSpec, spec/models/accounting/ and spec/services/accounting/)

16.1.1 Account Model (spec/models/accounting/account_spec.rb)
  - validates presence of cooperative_id, name, account_code, account_type
  - validates account_type is one of: asset, equity, liability, revenue, expense
  - validates account_code uniqueness scoped to cooperative_id
  - status enum: accepts 'active', 'archived'
  - postable boolean: defaults to true
  - Account with status 'archived' returns postable? == false
  - Account with status 'active' and postable true: postable? == true
  - Account with status 'active' and postable false: postable? == false
  - balance method returns Money object in PHP currency
  - balance for Asset account: sum of debit_amount_lines - sum of credit_amount_lines
  - balance for Liability/Credit account: sum of credit_amount_lines - sum of debit_amount_lines
  - contra account reverses the above calculation
  - balance with no AmountLines returns Money.new(0)
  - balance filters by from_date and to_date correctly
  - normal_credit_balance? returns correct value per account_type
  - .balance class method sums all account balances correctly
  - belongs_to :ledger association works
  - has_many :amount_lines association works

16.1.2 Ledger Model (spec/models/accounting/ledger_spec.rb)
  - validates presence of cooperative_id, name, account_code
  - has_ancestry is declared
  - has_many :accounts association works
  - balance sums all descendant account balances correctly
  - subtree of accounts returns correct accounts including nested children

16.1.3 AmountLine Model (spec/models/accounting/amount_line_spec.rb)
  - validates presence of cooperative_id, entry_id, account_id, amount_cents, amount_type
  - amount_type accepts 'debit' and 'credit'
  - amount_cents must be positive integer
  - belongs_to :entry and belongs_to :account associations work
  - monetizes :amount_cents correctly
  - scope .debit returns only debit amount_lines
  - scope .credit returns only credit amount_lines

16.1.4 ChartOfAccountsService (spec/services/accounting/chart_of_accounts_service_spec.rb)
  Existing spec file at 174 lines. ADD these tests:
  - #search with empty query returns empty
  - #search with partial match on account_code returns matching accounts
  - #search with partial match on account name returns matching accounts
  - #search matches ledger names (ancestry path)
  - #search returns both ledgers and accounts grouped
  - #search limits results appropriately (no more than 20 per group)
  - #search is case-insensitive
  - #accounts_list with no filters returns paginated accounts
  - #accounts_list filters by ledger_id (uses subtree_ids)
  - #accounts_list filters by account_type (asset/liability/equity/revenue/expense)
  - #accounts_list filters by status (active/archived)
  - #accounts_list filters by postable (true/false)
  - #accounts_list filters by contra (true/false)
  - #accounts_list filters by has_activity (has AmountLines in date range)
  - #accounts_list filters by zero_balance (current_balance == 0)
  - #accounts_list combined filters work together (AND logic)
  - #accounts_list pagination returns correct page size
  - #tree_data returns nested hash of ledgers with correct ancestry roots
  - #tree_data includes aggregated balance per ledger node
  - #tree_data includes account_count per ledger node
  - #tree_data lazy-loading hint: only returns root nodes unless subtree requested
  - #account_inspector returns account with full ledger path string
  - #account_inspector returns recent AmountLines (last 10)
  - #account_inspector returns debit/credit totals
  - #account_inspector includes posting eligibility status

16.1.5 Account Balance Aggregation (spec/services/accounting/)
  - balance aggregation sums correctly across multiple AmountLines
  - balance aggregation for accounts with mixed debit and credit entries
  - balance aggregation for ledger with multiple child accounts
  - balance aggregation excludes AmountLines from voided Entries

16.1.6 Posting Eligibility (spec/services/accounting/account_status_service_spec.rb — new file)
  - Account status 'active' and postable true: is_postable? == true
  - Account status 'active' and postable false: is_postable? == false
  - Account status 'archived': is_postable? == false
  - raises AccountNotPostableError when attempting to post to ineligible account
  - AccountNotPostableError has account_code and status in message

16.2 Integration Tests

16.2.1 ChartOfAccountsController (spec/requests/accounting/chart_of_accounts_spec.rb)
  - GET /accounting/chart_of_accounts returns 200 with turbo_stream
  - GET /accounting/chart_of_accounts/search with valid query returns JSON with ledgers and accounts
  - GET /accounting/chart_of_accounts/search with blank query returns empty results
  - GET /accounting/chart_of_accounts/search with no cooperative_id returns 400
  - GET /accounting/chart_of_accounts/accounts returns 200 with filtered accounts
  - GET /accounting/chart_of_accounts/accounts with ledger_id filter scopes to subtree
  - GET /accounting/chart_of_accounts/accounts with account_type filter returns correct type
  - GET /accounting/chart_of_accounts/accounts with status filter returns correct status
  - GET /accounting/chart_of_accounts/accounts requires authenticated session

16.2.2 Account Detail Flow (spec/requests/accounting/accounts_spec.rb)
  - GET /accounting/accounts/:id returns 200
  - response includes balance summary (Money object rendered)
  - response includes AmountLines (entry lines) with pagination
  - AmountLines are sorted by entry_date descending
  - filter by from_date/to_date limits AmountLines to range
  - filter by amount_type (debit/credit) filters correctly
  - response includes audit trail (created_by, modified timestamps)
  - archived account shows warning banner
  - non-postable account shows warning banner

16.3 E2E Tests (Playwright, spec/e2e/accounting/chart_of_accounts/)

FILE: spec/e2e/accounting/chart_of_accounts/search.spec.ts
  - page loads chart of accounts workbench
  - global search returns results for partial account name match
  - global search returns results for partial account code match
  - global search returns results for ledger name match
  - global search groups results: Ledgers section, Accounts section
  - global search shows no results state with helpful message when query has no match
  - global search is instant (<300ms perceived)
  - clicking a search result navigates to account detail view

FILE: spec/e2e/accounting/chart_of_accounts/account_detail.spec.ts
  - clicking account row in table navigates to /accounting/accounts/:id
  - account detail page shows summary: balance, ledger path, status, posting eligibility
  - balance is displayed as formatted PHP currency
  - posting eligibility shows checkmark for active/postable accounts
  - posting eligibility shows warning icon for archived accounts
  - posting eligibility shows warning icon for non-postable accounts
  - transactions section shows AmountLines with debit/credit split
  - transactions are sortable by date (default: newest first)
  - transactions are filterable by date range
  - audit trail section shows who created and when
  - back button returns to chart of accounts workbench

FILE: spec/e2e/accounting/chart_of_accounts/ledger_tree.spec.ts
  - left panel shows ledger tree with root ledgers expanded
  - ledger nodes show aggregated balance
  - ledger nodes show account count
  - clicking ledger node loads child ledgers and accounts into center panel
  - expanding a ledger node loads children lazily
  - account counts under ledger nodes are accurate
  - ledger tree balances match account table totals

FILE: spec/e2e/accounting/chart_of_accounts/filters.spec.ts
  - filter by Account Type (Asset) shows only asset accounts
  - filter by Account Type ( Liability) shows only liability accounts
  - filter by Status (Active) shows only active accounts
  - filter by Status (Archived) shows only archived accounts
  - filter by Posting Allowed (Yes) shows only postable accounts
  - filter by Posting Allowed (No) shows only non-postable accounts
  - filters are additive (selecting multiple filters narrows results)
  - clearing all filters returns to full list
  - filter state persists when navigating back from account detail
  - URL reflects filter state (bookmarkable)

FILE: spec/e2e/accounting/chart_of_accounts/account_inspector_warnings.spec.ts
  - archived account row shows archived indicator in table
  - archived account shows warning banner in account detail
  - non-postable account shows warning icon in account detail
  - hovering warning icon shows tooltip explaining the restriction
  - accountant can still view transactions for archived accounts (read-only)
  - posting attempt on archived/non-postable account shows error via PostingEngine
17. Implementation Spec

17.1 Database Migrations (run in order)

M1: Add status and postable to accounts
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_status_and_postable_to_accounts.rb
class AddStatusAndPostableToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :status, :string, default: 'active', null: false
    add_index :accounts, [:cooperative_id, :status]

    add_column :accounts, :postable, :boolean, default: true, null: false

    add_column :accounts, :created_by_id, :uuid, null: true
    add_column :accounts, :modified_by_id, :uuid, null: true
    add_index :accounts, :created_by_id
    add_index :accounts, :modified_by_id
  end
end
```

M2: Add current_balance_cents to accounts (optional enhancement — see 14.5.7)
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_current_balance_cents_to_accounts.rb
class AddCurrentBalanceCentsToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :current_balance_cents, :integer, default: 0, null: false
    # No index needed — this is updated by background job, not queried directly
  end
end
```

M3: Add current_balance_cents to ledgers (optional enhancement)
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_current_balance_cents_to_ledgers.rb
class AddCurrentBalanceCentsToLedgers < ActiveRecord::Migration[8.0]
  def change
    add_column :ledgers, :current_balance_cents, :integer, default: 0, null: false
  end
end
```

17.2 Model Changes

17.2.1 Accounting::Account (app/models/accounting/account.rb)
Add enum declarations:
  enum :status, { active: "active", archived: "archived" }, default: "active"
  attribute :postable, :boolean, default: true

Add callback for modified_by_id:
  before_validation on: :update do
    self.modified_by_id = Current.user.id if defined?(Current) && Current.user
  end

Add scope:
  scope :postable, -> { where(status: 'active', postable: true) }
  scope :active, -> { where(status: 'active') }
  scope :archived, -> { where(status: 'archived') }

Add method:
  def postable?
    status == 'active' && postable == true
  end

17.2.2 Accounting::Account (add to app/models/accounting/account.rb)
Add constant for normal credit balance mapping:
  NORMAL_BALANCE = {
    asset: :debit,
    expense: :debit,
    liability: :credit,
    equity: :credit,
    revenue: :credit
  }.with_indifferent_access

17.2.3 ApplicationRecord callback (app/models/application_record.rb)
Add if not present:
  around_update :track_modified_by

  private

  def track_modified_by
    if saved_change_to_attribute? && respond_to?(:modified_by_id)
      self.modified_by_id = Current.user.id if defined?(Current) && Current.user
    end
    yield
  end

17.3 Service Changes

17.3.1 ChartOfAccountsService (app/services/accounting/chart_of_accounts_service.rb)
Update #account_inspector to include status and postable:
  def account_inspector(account_id)
    account = Account.includes(:ledger).find(account_id)
    {
      account: account,
      ledger_path: build_ledger_path(account.ledger),
      recent_lines: account.amount_lines.includes(:entry).order(created_at: :desc).limit(10),
      debit_total: debit_sum(account),
      credit_total: credit_sum(account),
      postable: account.postable?,
      status: account.status
    }
  end

Add private helpers:
  private

  def debit_sum(account)
    account.amount_lines.joins(:entry).where(amount_type: :debit).sum(:amount_cents)
  end

  def credit_sum(account)
    account.amount_lines.joins(:entry).where(amount_type: :credit).sum(:amount_cents)
  end

  def build_ledger_path(ledger)
    return nil unless ledger
    ledger.ancestors.pluck(:name).join(" / ") + " / #{ledger.name}"
  end

17.3.2 New AccountStatusService (app/services/accounting/account_status_service.rb)
```ruby
module Accounting
  class AccountStatusService
    def initialize(account)
      @account = account
    end

    def postable?
      @account.status == 'active' && @account.postable == true
    end

    def validate_postable!
      raise AccountNotPostableError, postable_error_message unless postable?
    end

    private

    def postable_error_message
      "Account #{@account.account_code} is #{@account.status} and postable=#{@account.postable}"
    end
  end

  class AccountNotPostableError < StandardError; end
end
```

17.3.3 Update PostingEngine (app/services/accounting/posting_engine.rb)
In #post!, after resolving accounts and before creating AmountLines, validate each account:
  accounts.each do |account|
    AccountStatusService.new(account).validate_postable!
  end

17.4 Controller Changes

17.4.1 Accounting::AccountsController (app/controllers/accounting/accounts_controller.rb)
Update #show to include status and postable in response:
  def show
    @account = Account.includes(:ledger, :amount_lines => :entry).find(params[:id])
    @postable = @account.postable?
    @status = @account.status
    # existing summary code...
  end

17.4.2 Accounting::ChartOfAccountsController (app/controllers/accounting/chart_of_accounts_controller.rb)
No changes needed — service already handles the data. Ensure accounts_list supports status and postable filter params.

17.5 Background Jobs

17.5.1 UpdateRunningBalancesJob (app/jobs/accounting/update_running_balances_job.rb)
EXISTING — verify it exists and is called by PostingEngine. If not present, create:
```ruby
module Accounting
  class UpdateRunningBalancesJob < ApplicationJob
    queue_as :default

    def perform(entry_id)
      entry = Entry.includes(:amount_lines).find(entry_id)
      return unless entry.posted?

      entry.amount_lines.each do |line|
        UpdateRunningBalances.new(
          cooperative_id: entry.cooperative_id,
          account_id: line.account_id,
          ledger_id: line.account.ledger_id,
          posted_date: entry.entry_date,
          amount_cents: line.amount_cents,
          amount_type: line.amount_type
        ).call
      end
    end
  end
end
```

17.5.2 RebuildRunningBalancesJob (app/jobs/accounting/rebuild_running_balances_job.rb)
EXISTING — already implemented via RebuildRunningBalancesService. Verify it runs correctly after migration.

17.6 Routes (config/routes.rb)

Existing routes are sufficient. Verify:
  get "chart_of_accounts"
  get "chart_of_accounts/search"
  get "chart_of_accounts/accounts"
  get "accounts/search"
  resources :accounts, only: [:show], module: :accounting

All are already present (confirmed from audit).

17.7 View Changes

17.7.1 Chart of Accounts Index (app/views/accounting/chart_of_accounts/index.html.erb)
Ensure filters are always visible: status filter dropdown, account_type filter, postable filter.
Add data attributes for Playwright test hooks:
  <div data-controller="chart-of-accounts" data-chart-of-accounts-status-filter-value="active">
  Each table row: <tr data-account-id="{{ account.id }}" data-account-status="{{ account.status }}">

17.7.2 Account Detail (app/views/accounting/accounts/show.html.erb)
Add warning banners above summary section:
  <% if @account.archived? %>
    <div class="bg-amber-100 border-l-4 border-amber-500 p-4 mb-4" data-test="archived-warning">
      <p class="text-amber-800">This account is archived. Posting is not allowed.</p>
    </div>
  <% end %>
  <% unless @account.postable? %>
    <div class="bg-amber-100 border-l-4 border-amber-500 p-4 mb-4" data-test="non-postable-warning">
      <p class="text-amber-800">This account is not postable. AmountLines cannot be created against it.</p>
    </div>
  <% end %>

Add data attributes:
  <span data-test="account-status"><%= @account.status %></span>
  <span data-test="account-postable"><%= @account.postable %></span>

17.8 Hotwire / Stimulus

17.8.1 chart_of_accounts_controller (app/javascript/controllers/chart_of_accounts_controller.js)
  - Uses global search input to call GET /chart_of_accounts/search
  - Updates accounts table via turbo_stream
  - Filter changes update accounts table via GET /chart_of_accounts/accounts with filter params
  - URL reflects filter state via history.pushState
  - Clicking account row navigates to /accounting/accounts/:id

17.9 Dependencies to Add

None required. All dependencies already exist:
  ancestry gem — already on Ledger
  money-rails — already on AmountLine
  Solid Queue — already configured
  Hotwire/Stimulus — already in use

17.10 Load Order / Dependencies

Migrations must run before code that uses status/postable. M1 (status/postable) is required for all other changes. M2/M3 (current_balance_cents) are optional and deferred.

17.11 Security Considerations

- All ChartOfAccountsController and AccountsController actions require authentication (verify before_filter or concern is applied)
- cooperative_id scoping is enforced at the service layer (ChartOfAccountsService already scopes to current_cooperative)
- Archived accounts remain visible in read-only mode — no write operations allowed
- Posting eligibility is enforced server-side in PostingEngine, not just in UI warnings

17.12 Performance Notes

- The existing ChartOfAccountsService#accounts_list uses ledger.subtree_ids for hierarchy filtering — this is efficient with the has_ancestry gem indexes
- Balance computation via Account#balance joins AmountLine + Entry and is on-demand. For <10k accounts this is fast. Pre-compute only if load testing shows it necessary.
- Global search on account_code and name uses SQL LIKE — add a database index on accounts.name if performance degrades:
  add_index :accounts, [:cooperative_id, :name]
  add_index :accounts, [:cooperative_id, :account_code]

18. Success Criteria

This feature is successful when:

accountants stop browsing trees manually
90%+ of account access happens via search
posting errors drop due to visibility
account lookup time drops to seconds, not minutes
ledger tree becomes secondary, not primary navigation
19. Final UX Philosophy

A Chart of Accounts is not a tree UI.
It is a financial search and validation system disguised as a tree.