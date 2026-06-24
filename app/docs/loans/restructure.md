Loan Restructuring & Refinancing Module

System: Coop Banking Platform (Rails 8 + Hotwire + existing Accounting Ledger)

1. OVERVIEW
1.1 Problem

Cooperatives currently handle loan restructuring manually or with weak system support:

No clear distinction between restructure vs refinance
Poor audit trail
Hidden credit risk
No versioned schedules
No visibility of loan lineage
1.2 Goal

Build a fully auditable, workflow-driven loan restructuring system supporting:

Modification Restructure (same loan)
Refinancing (new loan replaces old loan)
Hybrid Restructure (partial payoff + modification)
1.3 Non-Goals
No replacement of accounting ledger
No credit scoring AI (optional later)
No payment gateway logic changes
2. CORE DESIGN PRINCIPLE

“Loans are immutable financial states connected through events and links.”

No loan record is ever silently modified without:

event log entry
schedule versioning
audit traceability
3. DOMAIN MODEL (FINAL)
3.1 Core Entities
Loan
Represents credit exposure
LoanSchedule
Versioned amortization schedule
LoanLink
Connects loan relationships (refinance/hybrid)
LoanEvent
Audit trail of all credit actions
3.2 Loan Link Types
Type	Meaning
modification	same loan, schedule change
refinance	new loan replaces old
hybrid	partial payoff + restructure
4. BUSINESS RULES
4.1 Modification Restructure
Same loan ID
New schedule version created
No principal movement
No LoanLink required (optional self-link for audit)
4.2 Refinancing
New loan created
Old loan fully paid via new loan proceeds
Old loan status = refinanced
LoanLink required
4.3 Hybrid Restructure
Partial payoff OR arrears capitalization
New loan may be created OR same loan modified
LoanLink required with amount
4.4 Constraints
Max restructures per loan = configurable (default 2)
Cannot refinance a closed loan
All restructures require approval workflow completion
5. LOAN STATE MACHINE
active
  ↓
past_due
  ↓
restructure_requested
  ↓
under_review
  ↓
approved / rejected
  ↓
(approved path)
   ├── modified
   ├── refinanced
   └── hybrid_restructured
  ↓
closed
6. SYSTEM FLOW (END-TO-END)
6.1 FLOW A — MODIFICATION RESTRUCTURE
Trigger
delinquency detected OR request from member
Steps
Create LoanRestructureCase
Credit officer proposes changes
System simulates new schedule
Approval workflow
Create new LoanSchedule version
Mark old schedule as superseded
Log LoanEvent
6.2 FLOW B — REFINANCING (NEW LOAN)
Steps
Create LoanRestructureCase
Generate payoff computation:
principal
interest
penalties
Create new Loan
Execute payoff using ledger:
debit new loan receivable
credit old loan receivable
Create LoanLink (refinance)
Close old loan
Activate new loan
Log LoanEvent
6.3 FLOW C — HYBRID RESTRUCTURE
Steps
Create case
Compute:
arrears capitalization
partial payoff (optional)
Choose:
modify existing loan OR create new loan
Create LoanLink (hybrid)
Generate new schedule
Approval required
Execute ledger adjustments
Log event
7. BACKEND SERVICES (RAILS)
7.1 Core Services
LoanRestructureService

Routes strategy:

call(type:)
  ModificationRestructure
  RefinanceRestructure
  HybridRestructure
end
ScheduleVersioningService
clones schedule
marks old as superseded
LoanPayoffService
computes full settlement amount
interacts with ledger
LoanLinkService
creates graph relationships
ApprovalWorkflowService
handles multi-level approval routing
8. DATABASE STRUCTURE (SUMMARY)
Loans
id
member_id
status
loan_type
receivable_account_id
interest_income_account_id
LoanSchedules
loan_id
version
status
LoanLinks
from_loan_id
to_loan_id
link_type
amount
LoanEvents
loan_id
event_type
metadata (jsonb)
9. HOTWIRE UI / UX FLOW (IMPORTANT)
9.1 LOAN DETAIL PAGE
Layout
[Loan Summary Card]
- Outstanding balance
- DPD
- Status
- Risk band

[Actions]
- 🔄 Restructure Loan
- 🔁 Refinance Loan
- ⚙ Hybrid Restructure
Turbo Frame Sections:
loan_summary
loan_schedule
loan_events
restructure_modal
9.2 RESTRUCTURE MODAL (HOTWIRE)
Step 1: Select Type
( ) Modification
( ) Refinance
( ) Hybrid

Turbo Frame:
restructure_form

Step 2: Inputs (dynamic per type)
Modification
interest rate
term extension
grace period
Refinance
new term
optional interest adjustment
shows payoff preview
Hybrid
arrears to capitalize
partial payoff slider
new terms
Step 3: Simulation Panel (REAL-TIME)

Right side Turbo Frame:

Old Payment: ₱5,000
New Payment: ₱3,200
Difference: -36%

Total Interest Impact
Risk Score Change
Step 4: Approval Routing Preview
Required approvals:
✔ Credit Officer
✔ Branch Manager
✔ Credit Committee (if > threshold)
Step 5: Submit

Creates:

LoanRestructureCase
LoanEvent (draft state)
9.3 APPROVAL DASHBOARD
View (Turbo Stream live updates)

List:

Pending restructures
Risk level
Loan exposure
Requested changes

Actions:

Approve
Reject
Request revision
9.4 EXECUTION SCREEN

After approval:

Shows:

Executing restructure...
✔ Schedule version created
✔ Ledger entries posted
✔ LoanLink created
✔ Old loan closed (if refinance)
9.5 LOAN HISTORY TIMELINE

Turbo Stream timeline:

2025-01 Disbursed
2025-06 Missed payments
2025-07 Modification restructure v2
2025-11 Refinance → Loan #B102 created

Includes clickable LoanLinks graph.

10. EDGE CASES
10.1 Partial Payment During Approval
lock loan state during case
10.2 Double Restructure Requests
prevent concurrent cases
10.3 Refinance Reversal
require reversal ledger entries
10.4 Hybrid Overlap
cannot stack multiple active hybrid cases
11. ACCEPTANCE CRITERIA

System is correct if:

Functional
 All 3 restructure types supported
 LoanLink graph always accurate
 No loan is modified without event log
 Schedule versioning works correctly
Accounting
 Ledger entries always balanced
 Payoff fully reconciles
UI
 Hotwire updates without full reload
 Simulation updates in real time
 Approval workflow visible live
Audit
 Every restructure is traceable end-to-end
 Loan lineage graph reconstructable
12. FINAL SYSTEM MENTAL MODEL

Think of your system as:

Loan = node
LoanLink = edge
LoanEvent = truth log
LoanSchedule = time-series state
Ledger = financial source of truth