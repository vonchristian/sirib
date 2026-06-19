Cooperative Teller Operations Module (Core Banking System)
1. Overview

The Teller Operations Module enables cooperative tellers to perform fast, secure, and auditable daily banking transactions. It is optimized for:

High-speed counter transactions
Minimal clicks per operation
Strict cash control and auditability
Seamless end-of-day (EOD) reconciliation
Role-based security enforcement

This module is the frontline cash handling system of the cooperative bank.

2. Goals
Primary Goals
Enable fast teller transactions (≤ 3 clicks per transaction type)
Maintain real-time cash position per teller and branch
Enforce strict cash control (vault, teller drawers, cash sessions)
Automate EOD reconciliation with variance detection
Generate printable audit-ready reports
Non-Goals
No external payments (GCash, cards, etc.)
No customer onboarding flows
No loan origination logic (only servicing visibility)
3. Users & Roles
Teller
Performs cash in/out transactions
Manages cash drawer session
Requests vault transfers
Treasurer
Approves large cash movements
Oversees teller balancing
Handles vault operations
Branch Manager
Views daily branch cash position
Reviews EOD reports and variances
Auditor (Read-only)
Access to all logs, reports, and history
4. Core Concepts
4.1 Cash Session (Teller Drawer Session)

A controlled working session where a teller handles cash.

States:

Open
Active
Suspended
Closed

Each session tracks:

Opening cash float
Cash receipts
Cash disbursements
Vault transfers in/out
Real-time cash balance
4.2 Vault

Central branch cash storage.

Only authorized users can initiate vault movements
Requires approval workflow (optional configurable)
4.3 Cash Movement Types
Cash Receipt (Cash In)

Examples:

Loan repayment (cash)
Deposit (savings/share capital)
Fees collected
Cash Disbursement (Cash Out)

Examples:

Withdrawals
Loan releases (cash portion)
Refunds
Vault Transfer
Teller → Vault (cash excess)
Vault → Teller (cash replenishment)
5. Teller Dashboard (UI/UX Requirements)
Design Principles
Slack-like quick navigation
Search-first interface
Minimal form input friction
Keyboard-friendly shortcuts
Layout
----------------------------------------------------
| Sidebar | Main Workspace | Right Context Panel  |
----------------------------------------------------
5.1 Sidebar (Fast Navigation)
Cash Session
Cash In (Receipts)
Cash Out (Disbursements)
Vault Transfers
Member Lookup
Transactions Today
Reports
EOD Closing
5.2 Main Workspace

Context-driven screens:

Default Home (Teller Console)
Current cash in drawer
Active session status
Today’s transaction summary
Quick actions:
Cash In
Cash Out
Vault Request
5.3 Right Panel (Context + AI Assist Optional)
Member details (when selected)
Transaction preview
Cash balance breakdown
Alerts (variance warnings, limits)
6. Cash Session Flow
6.1 Open Cash Session

Step 1: Login

Teller logs in with MFA (TOTP required)

Step 2: Open Session Form

Opening cash amount
Optional remarks
treasurer approval (configurable threshold)

System Actions:

Creates CashSession record
Locks teller drawer for branch mapping
Initializes cash ledger
6.2 Active Session Operations

During session:

All transactions are tied to session_id
Real-time balance updates
Automatic cash ledger posting
6.3 Suspend Session (Break Mode)
Temporarily locks transactions
Cash remains assigned to teller
6.4 Close Session (EOD trigger optional)

Moves to reconciliation flow.

7. Cash Transactions
7.1 Cash Receipt Flow

Examples: deposit, loan repayment

Steps:

Select Member
Select Account Type
Enter amount
Add optional reference
Confirm

System:

Increase teller cash balance
Create CashLedger entry (credit)
Generate receipt
7.2 Cash Disbursement Flow

Examples: withdrawals

Steps:

Search member/account
Validate available balance
Enter withdrawal amount
Confirm (optional treasurer/manager approval threshold)

System:

Decrease teller cash
Create CashLedger entry (debit)
Print payout slip
8. Vault Transfer Flow
8.1 Teller → Vault (Cash Excess)

Triggered when:

Teller exceeds max cash threshold

Steps:

Enter amount
Select vault destination
treasurer approval (optional)
Confirm transfer

System:

Decrease teller cash
Increase vault balance
Audit log created
8.2 Vault → Teller (Cash Replenishment)

Steps:

Request cash float
treasurer approval
Receive cash
Confirm receipt

System:

Increase teller cash
Decrease vault balance
9. End of Day (EOD) Closing Flow
9.1 Trigger
Teller initiates EOD or system cutoff time triggers it
9.2 Cash Count Form (Critical Flow)

Teller inputs physical cash:

Denomination Input Table:
Denomination	Count	Subtotal
1000		
500		
200		
100		
50		
20		
Coins		

System auto-calculates total.

9.3 System Reconciliation

System computes:

Expected Cash = Opening + Receipts - Disbursements ± Vault Transfers
Variance = Actual Count - Expected Cash
9.4 Variance Handling
Cases:
Zero variance → auto-approve closure
Small variance → treasurer review
Large variance → mandatory investigation flag
9.5 EOD Reports Generated
Teller Cash Summary
Transaction Journal
Vault Movement Report
Variance Report
Branch Cash Position Report

All reports:

Printable (PDF)
Exportable (CSV)
Digitally signed
10. Search & Navigation Requirements
Global Search (must be instant)

Search by:

Member name
Account number
Transaction ID
Cash session ID

Features:

Fuzzy search
Keyboard shortcut (Ctrl + K)
Instant preview panel
11. Security Requirements
Authentication
Password + TOTP MFA required
Session timeout (configurable)
Authorization (RBAC)
Teller: limited to own session
treasurer: approvals + vault access
Auditor: read-only
Audit Trail

Every action logs:

user_id
timestamp
IP/device
before/after state
12. Performance Requirements
Transaction commit: < 300ms
Search response: < 200ms
EOD generation: < 5 seconds per teller
Must support offline-safe queueing (optional future enhancement)
13. Data Models (High-Level)
CashSession
CashTransaction
CashLedgerEntry
Vault
VaultTransfer
TellerDrawer
EODReport
DenominationCount
AuditLog
14. Additional Teller Operations (Recommended)
Included in MVP Scope
Balance inquiry
Transaction reversal (with approval)
Cash adjustment (treasurer only)
Member quick view
Future Enhancements
Cheque handling
Check clearing tracking
Teller performance analytics
Fraud anomaly detection
AI-assisted cash forecasting
15. Acceptance Criteria
Teller can complete cash in/out in < 30 seconds
Cash session always balances or flags variance
EOD report is reproducible from ledger
No transaction can exist outside a session
All vault movements are fully auditable
Search returns results instantly across all entities