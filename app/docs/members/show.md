Member Profile (Show Page)
Coop Operations Platform (Rails 8 + Hotwire)
Goal

Design a Member Profile page that becomes the primary workspace for cooperative staff whenever they search and open a member.

The page should answer nearly every question staff have about a member without navigating across multiple modules.

This page is read-focused, while allowing quick navigation to related records.

Users
Teller
Membership Officer
Loan Officer
Accountant
Branch Manager
Cashier
Customer Service
Primary User Stories

As a staff member, I want to:

quickly verify the member
immediately see all financial relationships
know whether the member is in good standing
jump directly into savings, loans, deposits or shares
avoid searching across different modules
Route
GET /members/:id
Layout
---------------------------------------------------------
Breadcrumb

← Members / Juan Dela Cruz

---------------------------------------------------------
Member Header

Photo / Avatar

Juan Dela Cruz
Member No. 000123
Active Member

Member Since
Branch
Membership Type
Contact Number
Email

Quick Actions

Edit Member
Print Profile
Open New Account
Create Loan
Create Deposit
---------------------------------------------------------

TABS

Overview
Savings
Time Deposits
Loans
Share Capital
Settings

The selected tab loads using Turbo Frames for fast navigation.

Header Summary Cards

Display immediately visible metrics.

Savings
Number of savings accounts
Total savings balance
Time Deposits
Active deposits
Total deposit amount
Loans
Active loans
Outstanding balance
Share Capital
Total subscribed shares
Paid share capital
Membership
Membership status
Date joined
Last transaction date
Tab: Overview (Default)

Purpose:

Provide a 30-second overview before drilling into details.

Sections:

Member Information
Member Number
Full Name
Birthdate
Gender
Civil Status
Address
Contact Numbers
Email
Membership Date
Membership Status
Branch
Financial Snapshot

Cards:

Savings Balance

Time Deposit Balance

Loan Balance

Share Capital

Available Loan Eligibility (future)

Recent Activity

Latest transactions across all modules.

Columns

Date

Module

Reference

Description

Amount

Running Balance (if applicable)

Alerts

Examples

Inactive savings account

Past due loan

Missing KYC document

Dormant member

Pending approval

No alerts should display an empty state.

Tab: Savings

Purpose:

View every savings account owned by the member.

Table

Account Number

Product

Status

Available Balance

Ledger Balance

Last Transaction

Actions

Clicking a row opens the Savings Account page.

Top-right action:

Open Savings Account
Tab: Time Deposits

Table

Certificate No.

Product

Principal

Interest Rate

Start Date

Maturity Date

Status

Actions

Top-right action

Open Time Deposit
Tab: Loans

Purpose

Loan officers should immediately understand the member's obligations.

Table

Loan Number

Loan Product

Principal

Outstanding Balance

Interest Rate

Monthly Amortization

Due Date

Status

Actions

Clicking opens Loan Details.

Top-right

Create Loan
Tab: Share Capital

Table

Certificate

Transaction Date

Shares Purchased

Amount

Running Share Balance

Status

Summary cards

Total Shares

Paid Share Capital

Average Cost (future)

Top-right

Purchase Shares
Tab: Settings

Administrative information only.

Sections

Membership
Edit member
Change status
Transfer branch
Documents

Uploaded IDs

KYC Documents

Membership Forms

Audit

Created By

Created At

Updated By

Updated At

Danger Zone

Deactivate Member

(Confirmation required.)

Navigation Principles

Tabs should never reload the entire page.

Use

Turbo Frames
Turbo Streams

Each tab should lazy-load independently.

Search

Every table supports

Search
Status filter
Product filter (where applicable)
Sort by newest
Pagination
Empty States

Savings

"No savings accounts."

Button

Open Savings Account

Loans

"No loans."

Button

Create Loan

Time Deposits

"No time deposits."

Button

Open Time Deposit"

Share Capital

"No share capital transactions."

Button

Purchase Shares
Performance

The page must remain responsive even for members with years of history.

Requirements

Eager load associations
Paginate each tab independently
Lazy load Turbo Frames
Avoid N+1 queries
Use counter caches where appropriate
Cache summary metrics when beneficial
Authorization

Permissions should be evaluated per tab.

Examples

Teller

View savings
No loan creation
No settings access

Loan Officer

Full loans
Read savings
No membership settings

Accountant

Read all financial accounts
No membership edits

Manager

Full access
Accessibility
Keyboard-accessible tab navigation
Visible active tab state
Screen-reader friendly headings
Responsive layout for tablets and laptops
Rails Structure

Controller

MembersController#show

Turbo Frame partials

members/
    show.html.erb

    tabs/
        _overview.html.erb
        _savings.html.erb
        _time_deposits.html.erb
        _loans.html.erb
        _share_capital.html.erb
        _settings.html.erb

    components/
        _member_header.html.erb
        _summary_cards.html.erb
Suggested Services
Members::ProfileSummaryService

Members::RecentActivityService

Members::SavingsSummaryService

Members::LoanSummaryService
Acceptance Criteria
Member profile loads in under 500 ms for typical members.
Header displays core member details and financial summary.
Default tab is Overview.
Tabs load independently via Turbo Frames without full-page refresh.
Savings tab lists all savings accounts with balances and quick actions.
Time Deposits tab lists all deposit certificates and maturity details.
Loans tab shows all loans with outstanding balances and due dates.
Share Capital tab displays share transactions and current holdings.
Settings tab exposes administrative information only to authorized users.
Search, filtering, sorting, and pagination work independently within each tab.
Empty states include context-appropriate call-to-action buttons.
Authorization is enforced per tab and action.
Page avoids N+1 queries and uses eager loading where appropriate.
Unit Tests
Request Specs
GET member profile
Member not found returns 404
Unauthorized users cannot access restricted tabs
Summary metrics render correctly
Service Specs
ProfileSummaryService
RecentActivityService
SavingsSummaryService
LoanSummaryService

Verify:

Totals
Counts
Outstanding balances
Recent activity ordering
Empty datasets
Playwright E2E Tests
Scenario 1

Open member profile.

Expect:

Header renders correctly.
Overview tab is selected.
Summary cards display.
Scenario 2

Switch between all tabs.

Expect:

Turbo navigation.
No full-page reload.
Correct content displayed.
Scenario 3

Savings tab.

Search by account number.
Open an account.
Verify account details page opens.
Scenario 4

Loans tab.

Filter active loans.
Open a loan.
Verify loan details page loads.
Scenario 5

Member with no accounts.

Expect:

Appropriate empty states.
Correct call-to-action buttons.
Scenario 6

Permission checks.

Log in as:

Teller
Loan Officer
Accountant
Manager

Verify each role only sees the tabs and actions they are authorized to access.