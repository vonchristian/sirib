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
aggregated balance
account count under leaf
Center Panel: Accounts Table (Main Work Area)

This is the MOST USED component.

Columns:

Account Code
Account Name
Ledger Path (breadcrumb)
Type (Asset/Liability/etc)
Balance (real-time or cached)
Status (Active/Archived)
Posting Allowed (yes/no)
Right Panel: Account Inspector

Shows when clicking an account:

Full ledger path
Recent EntryLines
Debit/Credit totals
Posting eligibility
Audit history preview
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

Cash and Cash Equivalents (Ledger)
Cash on Hand (Ledger)
Cash in Bank - LandBank (Account)
Cash in Bank - PNB (Account)
Search result grouping

Grouped by:

Ledger hierarchy first
Accounts second
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
jump directly to account inspector
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
15. Frontend Components (Rails 8 + Hotwire)
CoA::TreePanel
CoA::AccountTable
CoA::AccountInspector
CoA::GlobalSearch
CoA::FilterBar
16. Testing Requirements
Unit
search ranking correctness
filter logic correctness
balance aggregation
Integration
search → open account → inspect flow
ledger drill-down correctness
E2E (Playwright)
Search account by partial name
Open account inspector
Validate posting eligibility
Filter by inactive accounts
Navigate ledger tree + verify balances
17. Success Criteria

This feature is successful when:

accountants stop browsing trees manually
90%+ of account access happens via search
posting errors drop due to visibility
account lookup time drops to seconds, not minutes
ledger tree becomes secondary, not primary navigation
18. Final UX Philosophy

A Chart of Accounts is not a tree UI.
It is a financial search and validation system disguised as a tree.