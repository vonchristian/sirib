PRD: Loan Aging Module v1
Overview

The Loan Aging Module classifies loans according to Days Past Due (DPD) and provides operational and management reporting for delinquency monitoring.

The module does not create accounting entries and does not affect the General Ledger.

Loan Aging is a reporting and risk-classification layer only.

Objectives

Provide visibility into:

Current loans
Delinquent loans
Portfolio at Risk (PAR)
Aging distribution
Collection priorities
Branch delinquency performance
Out of Scope

The following are explicitly excluded:

Loan loss provisioning
Allowance for credit losses
Expected credit loss calculations
Write-offs
Charge-offs
General Ledger postings
Accounting reclassifications
BSP reserve computations

These will be implemented in a future Credit Risk Management module.

Existing Models
Loan
LoanSchedule
LoanTransaction
Member
Branch
New Models
LoanAgingGroup

Defines aging bucket configuration.

class LoanAgingGroup < ApplicationRecord
  has_many :loan_agings
end

Schema:

name

min_days
max_days

display_order

active

created_at
updated_at

Seed Data:

Name	Min Days	Max Days
Current	0	0
1-30 Days	1	30
31-60 Days	31	60
61-90 Days	61	90
91-180 Days	91	180
Over 180 Days	181	NULL
LoanAging

Stores the current aging status of a loan.

class LoanAging < ApplicationRecord
  belongs_to :loan
  belongs_to :loan_aging_group
end

Schema:

loan_id

loan_aging_group_id

days_past_due

oldest_unpaid_due_date

outstanding_principal
outstanding_interest
penalty_amount

total_exposure

calculated_at

created_at
updated_at

One active LoanAging record per loan.

Aging Calculation Rules
Step 1

Find oldest unpaid installment.

loan.loan_schedules.unpaid.order(:due_date).first
Step 2

If no unpaid schedule exists:

DPD = 0
Bucket = Current
Step 3

Otherwise:

DPD =
As Of Date - Oldest Unpaid Due Date
Step 4

Determine aging bucket using LoanAgingGroup.

Example:

DPD = 45

Assigned Group:

31-60 Days
Portfolio at Risk
PAR30

Definition:

Outstanding Balance
for Loans with DPD > 30

Formula:

PAR30 =
PAR30 Exposure
/
Total Loan Portfolio
PAR60
DPD > 60
PAR90
DPD > 90
Dashboard

Route:

/lending/loan_aging
KPI Cards

Display:

Total Portfolio
Delinquent Portfolio
PAR30
PAR60
PAR90
Delinquent Loan Count
Delinquent Member Count
Aging Distribution

Display exposure by bucket.

Example:

Current          50M
1-30             10M
31-60             5M
61-90             3M
91-180            2M
180+              1M
Branch Performance

Display:

Branch	Portfolio	Delinquent	PAR30

Supports sorting by worst-performing branches.

Delinquent Loan Listing

Columns:

Loan Number
Borrower
Branch
Product
Outstanding Principal
Outstanding Interest
Penalty
Total Exposure
Days Past Due
Aging Group

Actions:

View Loan
View Schedule

Read-only module.

Filters

Supported Filters:

Branch
Product
Aging Group
Days Past Due Range
As Of Date
Snapshot Reporting
LoanAgingSnapshot

Stores daily portfolio statistics.

Schema:

snapshot_date

loan_aging_group_id

loan_count
member_count

principal_amount
interest_amount

total_exposure

Generated nightly.

Recalculation Triggers

Loan aging recalculates when:

Payment posted
Loan released
Loan restructured
Schedule adjusted
Nightly portfolio refresh
Permissions

Collection Officer

View

Branch Manager

View branch data

Credit Manager

View all

Auditor

Read only
Hotwire Requirements

Use Turbo Frames for:

Dashboard cards
Filters
Aging tables

Use Turbo Streams for:

Payment-triggered aging refresh
Dashboard updates

No full page reloads.

Acceptance Criteria
Every active loan has one LoanAging record.
DPD calculations are accurate.
Aging bucket assignment is accurate.
PAR30, PAR60, PAR90 calculations are accurate.
Dashboard loads under 2 seconds for 100,000 loans.
Historical snapshots can be viewed by date.
No General Ledger entries are created.
No accounting balances are modified.