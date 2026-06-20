External Banking Domain (Rails 8 Coop Core Banking)
SYSTEM CONTEXT

You are building a Cooperative Core Banking System (Rails 8 + Hotwire).

The system has:

Internal Ledger (JournalEntry system) → SOURCE OF TRUTH
External Banking Module → OBSERVATION + RECONCILIATION LAYER ONLY

External banking data must NEVER modify internal ledger automatically.

DOMAIN MODULE
Module Name

external_banking

OBJECTIVE (END GOAL FOR OPENCODE)

Build a fully functional Rails 8 module that allows:

Creating and managing external bank accounts
Uploading bank statements (PDF/CSV/images)
Extracting external transactions
Viewing external balances over time
Matching external transactions to internal JournalEntry
Supporting partial, split, and multi-match allocations
Providing a reconciliation UI workflow (human-in-the-loop)
CORE PRINCIPLE (NON-NEGOTIABLE)

Internal Ledger is authoritative. External bank data is only a mirror + reconciliation reference.

System must NEVER:

auto-post journal entries from external bank data
modify ledger balances based on external statements
DOMAIN ROUTE STRUCTURE

All routes under:

/external_banking

Suggested pages:

/external_banking/banks
/external_banking/accounts
/external_banking/accounts/:id
/external_banking/documents
/external_banking/reconciliation/:account_id
DATA MODELS (STRICT)
1. ExternalBank

Represents a bank institution.

name: string
code: string (optional)
country: string
status: enum[:active, :inactive]
cash_on_hand_ledger (auto create child under Cash in Bank ledger)
interest_income_ledger ((auto create child under Interest Income from deposits ledger)
2. ExternalBankAccount

Represents a specific bank account.

external_bank_id: fk
account_name: string
account_number: string (encrypted)
account_type: string
currency: string
current_balance: decimal (cached latest)
last_synced_at: datetime
status: enum[:active, :inactive]
cash_on_hand_account_id: Accounting::Account association auto create under cash_on_hand_ledger of external bank
interest_income_account_id: Accounting::Account association auto create under interest_income_ledger of external bank
3. ExternalBankDocument

Represents uploaded bank statements.

external_bank_account_id: fk
file: attachment (ActiveStorage)
document_type: enum[:statement, :export, :passbook_scan]
period_start: date
period_end: date
processing_status: enum[:pending, :processing, :parsed, :failed]
metadata: jsonb
4. ExternalBankTransaction

Canonical normalized transaction extracted from documents or API.

external_bank_account_id: fk
external_bank_document_id: fk (nullable)
transaction_date: date
description: text
reference_number: string
amount: decimal
direction: enum[:debit, :credit]
running_balance: decimal (nullable)
hash_signature: string (required, UNIQUE)
metadata: jsonb
Rules:
hash_signature MUST prevent duplicates
transactions are immutable after creation
5. ExternalBankTransactionAllocation

Bridge between external transactions and internal ledger.

external_bank_transaction_id: fk
journal_entry_id: fk (internal ledger)
allocated_amount: decimal
status: enum[:suggested, :confirmed, :rejected]
confidence_score: decimal (0–1 optional AI support)
created_by_id: fk (user)
Rules:
supports partial allocation
supports multiple allocations per transaction
does NOT affect JournalEntry automatically
CORE WORKFLOWS (IMPLEMENTATION REQUIRED)
1. Bank Setup Flow

User:

creates ExternalBank
creates ExternalBankAccount under it

System:

initializes account tracking
2. Statement Upload Flow

User uploads file → ExternalBankDocument

System:

stores file (ActiveStorage)
parses file asynchronously (Solid Queue)
extracts transactions
generates ExternalBankTransaction records
ensures idempotency via hash_signature
3. Transaction Normalization Rules

Each extracted transaction must:

belong to an account
have a unique hash_signature
preserve original description
preserve amount + direction
4. Reconciliation Flow (Human-in-the-loop)

UI shows:

Left:

ExternalBankTransaction

Right:

Suggested JournalEntry matches

User actions:

Confirm match
Reject match
Split allocation
Partial allocation

System stores:

ExternalBankTransactionAllocation
5. Balance Tracking

System computes:

latest external balance per account
derived from last transaction running_balance OR sum(debits/credits fallback)
BUSINESS RULES
Truth Model
JournalEntry = truth
ExternalBankTransaction = reference only
Matching Rules
One transaction → many journal entries allowed
One journal entry → many external transactions allowed
Partial allocation allowed always
Idempotency
hash_signature MUST prevent duplicates
EDGE CASES (MUST HANDLE)
Duplicate statement uploads
Bank lumps multiple payments into one transaction
Missing reference numbers (OCR failure)
Incorrect OCR amounts
Multi-currency mismatch (flag only, do not convert automatically)
Out-of-order transactions
UI REQUIREMENTS (HOTWIRE)

Must implement:

Accounts Page
list external banks + accounts
current balance preview
Account Detail Page
transaction list (paginated)
balance timeline
upload statement button
Documents Page
list uploads
processing status
Reconciliation Page
split view:
external transactions (left)
journal entries (right)
actions:
match
split
confirm
BACKGROUND JOBS (REQUIRED)

Use Solid Queue:

ParseExternalBankDocumentJob
ExtractExternalTransactionsJob
ComputeExternalBalanceJob
SuggestReconciliationMatchesJob (future-ready hook)
NON-FUNCTIONAL REQUIREMENTS
All document uploads must be encrypted at rest
Audit log ALL reconciliation actions
Must support high volume (100k+ transactions/account)
Indexed columns:
hash_signature (unique)
external_bank_account_id + transaction_date
Must be Rails 8 Hotwire-first (no heavy frontend frameworks)
MVP SCOPE (OPENCODE MUST IMPLEMENT FIRST)
MUST BUILD
Models + migrations
CRUD for banks + accounts
Document upload
Transaction ingestion (basic CSV parser acceptable)
Transaction listing UI
Basic reconciliation (manual match only)
Allocation records
PHASE 2 (DO NOT IMPLEMENT YET)
AI matching engine
OCR improvement pipeline
Bank API integrations
Auto-suggestions ranking system
Anomaly detection
FINAL OUTPUT EXPECTATION FOR OPENCODE

Generate:

Rails 8 schema (migrations)
Models with associations + validations
Controllers (Hotwire-ready)
Basic UI views
Background jobs
Service objects for:
document parsing
transaction normalization
Minimal reconciliation UI flow
SUCCESS CRITERIA

System is successful when:

User can upload bank statement
Transactions are extracted and stored
Transactions can be viewed per account
User can manually match transactions to JournalEntries
Allocations are persisted and auditable
Internal ledger remains untouched