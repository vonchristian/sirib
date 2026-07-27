# PRD: Utility Bill Payment & Auto-Pay

> **Status:** Draft · **Owner:** CTO · **Version:** 1.0
> **Dependency:** Core Banking Foundation + Inter-Cooperative Transfers
> **Target:** Phase 3.5 — Bill payment as a cooperative network service

---

## 1. Executive Summary

A member of any cooperative on the Sirib network walks into their cooperative branch or opens their member portal and pays their Meralco (electricity), Maynilad (water), PLDT (internet), or any other utility bill — and optionally sets it to auto-pay from their savings account each month.

The cooperative becomes a bill payment collection agent for utility providers. The network enables any cooperative to accept payments for any biller, regardless of which cooperative the member belongs to. Settlement flows from member → cooperative → Sirib network → utility provider.

This is not just a bill payment feature. It is the bridge between the cooperative economy and the mainstream economy. It makes cooperatives relevant in members' daily financial lives.

---

## 2. Why This Matters

| Reason | Impact |
|--------|--------|
| **Daily relevance** | Members pay bills monthly. If they can do it through their cooperative, they visit the coop (or portal) monthly. This builds habit, loyalty, and cross-sell opportunity. |
| **Revenue** | Bill payment commissions (typically PHP 5–20 per transaction) add up. For a coop with 5,000 paying members, that's PHP 300K–1.2M/year in pure commission income. |
| **Foot traffic** | Bill payment drives members into branches, where they also deposit savings, apply for loans, and buy shares. |
| **Network stickiness** | The more utilities a member can pay through their cooperative, the harder it is to leave. |
| **Auto-pay = core account engagement** | When a member's utility is auto-paid from their savings account, that account becomes their primary transaction account. Direct deposits, loans, and other products follow. |
| **Cross-coop value** | A member far from their home coop can pay bills at any network cooperative. This makes the entire network useful to every member. |

---

## 3. User Personas & Flows

### 3.1 Walk-In Teller Payment

```
Persona: Aling Nena, 58, market vendor, Coop A member
Scenario: Monthly Meralco bill due tomorrow

1. Aling Nena walks into Coop A branch (any branch, not just her home coop)
2. Hands bill to teller (or gives account number)
3. Teller enters: Biller = Meralco, Account = 1234-5678-90
4. System fetches: "Meralco: PHP 1,245.00, Due: July 20"
5. Aling Nena pays PHP 1,245 in cash
6. System prints receipt: "Meralco Payment — Reference: SIR-MER-20260716-001"
7. Meralco account is credited (via batch settlement)
8. Aling Nena receives SMS confirmation
```

### 3.2 Portal Self-Service Payment

```
Persona: James, 32, teacher, Coop B member
Scenario: Pay internet bill from home

1. James logs into Coop B member portal
2. Clicks "Pay Bills"
3. Selects "PLDT Home" from biller list
4. Enters account number: 123-456-789
5. System shows: "PLDT Home Fiber — PHP 1,899.00, Due: July 25"
6. James selects source: Savings Account (PHP 12,500.00 available)
7. Confirms with MFA (TOTP)
8. "Payment successful! Reference: SIR-PLD-20260716-042"
9. James receives email receipt
10. Savings account debited PHP 1,899.00
```

### 3.3 Auto-Pay Setup

```
Persona: Susan, 41, OFW family, Coop C member
Scenario: Never miss a utility payment again

1. Susan logs into Coop C portal
2. Pays her Meralco bill as a one-time payment
3. After payment, sees: "Set up Auto-Pay for this bill?"
4. Susan clicks "Yes, enroll in Auto-Pay"
5. Selects source: Savings Account (PHP 45,000.00)
6. Sets: Auto-pay 3 days before due date
7. Sets monthly limit: PHP 5,000.00
8. Confirms with MFA
9. "Auto-Pay enrolled! Meralco bill will be paid automatically each month."
10. Each month: system pays bill on schedule, Susan gets SMS notification
```

### 3.4 Teller-Initiated Auto-Pay (for Non-Digital Members)

```
Persona: Mang Jose, 67, farmer, no smartphone
Scenario: Needs auto-pay without a portal

1. Mang Jose visits Coop A teller
2. "I want my electric bill paid automatically"
3. Teller sets up auto-pay on his behalf (with signed authorization form)
4. Auto-pay linked to his savings account
5. Monthly: system auto-pays, Mang Jose gets SMS notification
6. If insufficient balance: system sends SMS alert, retries in 3 days
```

---

## 4. Functional Requirements

### 4.1 Biller Management (Admin)

| ID | Requirement | Priority |
|----|-------------|----------|
| BLR-01 | Network operator maintains a master biller directory (Meralco, Maynilad, PLDT, Globe, Manila Water, etc.) | P0 |
| BLR-02 | Each biller has: name, code, category (electricity, water, telecom, insurance, government), logo, support phone | P0 |
| BLR-03 | Biller can define required fields for account validation (e.g., account number only, or account number + service ID) | P0 |
| BLR-04 | Biller can define payment cutoff times and settlement schedule | P1 |
| BLR-05 | Biller can define minimum and maximum payment amounts | P1 |
| BLR-06 | Biller can temporarily suspend payment acceptance (maintenance window) | P1 |
| BLR-07 | Cooperative admins select which billers to offer (not all coops may offer all billers) | P0 |
| BLR-08 | Cooperative can set its own commission per biller (override network default) | P1 |
| BLR-09 | Biller integration status is visible: active, degraded, maintenance, inactive | P0 |

### 4.2 Account Validation & Inquiry

| ID | Requirement | Priority |
|----|-------------|----------|
| VAL-01 | System validates biller account number format before submitting payment | P0 |
| VAL-02 | System displays account holder name (when biller API provides it) for member confirmation | P0 |
| VAL-03 | System displays current amount due, due date, and any past-due amounts | P0 |
| VAL-04 | System caches bill inquiry results for TTL (configurable per biller, default 5 minutes) | P1 |
| VAL-05 | If biller is unreachable, system shows "Biller temporarily unavailable — please try again later" | P0 |
| VAL-06 | System supports partial payment if biller allows it | P2 |

### 4.3 Payment Execution

| ID | Requirement | Priority |
|----|-------------|----------|
| PAY-01 | Member can pay from: cash (teller), savings account, or share capital (if allowed) | P0 |
| PAY-02 | Payment is idempotent — same reference number cannot be paid twice | P0 |
| PAY-03 | Payment creates a journal entry (debit cash/member account, credit biller clearing account) | P0 |
| PAY-04 | Payment generates a receipt with: reference number, biller name, account number, amount, date, time, teller/channel | P0 |
| PAY-05 | Receipt can be printed (teller) or downloaded as PDF (portal) | P1 |
| PAY-06 | Payment confirmation is sent via SMS and/or email (member preference) | P0 |
| PAY-07 | Payment can be made at any network cooperative, not just the member's home coop | P0 |
| PAY-08 | Cross-coop payment routes settlement through the network settlement layer | P0 |
| PAY-09 | Payment shows as "Pending" until confirmed by biller (async), then "Completed" | P0 |
| PAY-10 | Failed payments are reversed within 24 hours with notification | P0 |

### 4.4 Auto-Pay / Scheduled Payments

| ID | Requirement | Priority |
|----|-------------|----------|
| AUT-01 | Member can enroll any eligible biller account in auto-pay | P0 |
| AUT-02 | Auto-pay runs N days before due date (configurable, default 3) | P0 |
| AUT-03 | Member sets a monthly maximum (safety cap) to prevent overpayment | P0 |
| AUT-04 | If auto-pay fails (insufficient balance, biller down), retry 3 days later | P0 |
| AUT-05 | After 3 failed attempts, auto-pay is suspended; member is notified | P0 |
| AUT-06 | Member receives notification before each auto-pay execution (N days before) | P1 |
| AUT-07 | Member receives notification after successful auto-pay | P0 |
| AUT-08 | Member can pause/resume/cancel auto-pay at any time | P0 |
| AUT-09 | Member can change the funding source for auto-pay | P0 |
| AUT-10 | Member can view upcoming scheduled auto-payments (calendar view) | P1 |
| AUT-11 | Auto-pay history is available in transaction history | P1 |
| AUT-12 | Teller can enroll/update/cancel auto-pay on behalf of member (with authorization) | P1 |

### 4.5 Settlement & Reconciliation

| ID | Requirement | Priority |
|----|-------------|----------|
| STL-01 | Payments are netted per biller per settlement cycle | P0 |
| STL-02 | Settlement cycle defaults to daily (T+1) but configurable per biller | P0 |
| STL-03 | Settlement report generated for each biller: total collected, fees deducted, net remittance | P0 |
| STL-04 | Each cooperative receives its own settlement report: commissions earned, amounts collected | P0 |
| STL-05 | Network operator (Sirib) takes a platform fee from each transaction | P1 |
| STL-06 | Unsettled payments (in-transit) are tracked in a clearing account | P0 |
| STL-07 | Reconciliation: biller's records vs Sirib network records — auto-matched daily | P1 |
| STL-08 | Discrepancies flagged for manual review | P1 |

### 4.6 Auto-Pay Business Rules

| Rule | Description |
|------|-------------|
| Auto-pay runs only on business days | If due date falls on weekend/holiday, run the last business day before |
| Insufficient balance: skip and retry | If savings balance < bill amount, skip, retry in 3 days |
| Two max retries per billing cycle | After 2 retries, suspend auto-pay for that billing cycle |
| Member notified on each failure | SMS/email on retry 1, retry 2, and suspension |
| Auto-pay respects biller cutoff | If biller cuts off at 5 PM, auto-pay runs at 9 AM to allow time |
| Safety cap enforcement | Auto-pay never exceeds the member-set monthly maximum |
| Auto-pay can be overridden | Member can manually pay a bill that has auto-pay; auto-pay skips that cycle |
| Auto-pay history is retained | 7 years per regulatory requirements |

---

## 5. Technical Architecture

### 5.1 Module Structure

```
app/
├── models/utility/           # New module: Utility Bill Payment
│   ├── biller.rb
│   ├── biller_account.rb
│   ├── bill_inquiry.rb
│   ├── bill_payment.rb
│   ├── bill_payment_fee.rb
│   └── auto_pay_enrollment.rb
│
├── controllers/utility/      # New controllers
│   ├── billers_controller.rb         # Biller directory (coop admin)
│   ├── bill_inquiries_controller.rb  # Inquiry (teller + portal)
│   ├── payments_controller.rb        # One-time payment
│   ├── auto_pay_enrollments_controller.rb
│   └── settlements_controller.rb     # Biller settlement (network admin)
│
├── services/utility/         # Business logic
│   ├── bill_inquiry_service.rb
│   ├── bill_payment_service.rb
│   ├── auto_pay_enrollment_service.rb
│   ├── auto_pay_execution_service.rb
│   └── biller_settlement_service.rb
│
├── jobs/utility/             # Async jobs
│   ├── auto_pay_daily_job.rb
│   └── bill_payment_confirmation_job.rb
│
└── views/utility/            # Views
    ├── billers/
    ├── payments/
    ├── auto_pay_enrollments/
    └── settlements/
```

### 5.2 Data Model

```ruby
# Biller directory (network-level, replicated to each coop)
create_table "utility_billers" do |t|
  t.string :code, null: false          # e.g., "MERALCO", "MAYNILAD"
  t.string :name, null: false          # e.g., "Meralco"
  t.string :category, null: false      # electricity, water, telecom, insurance, govt
  t.string :logo_url
  t.jsonb :account_fields, default: [] # [{name: "account_number", label: "Account No.", required: true}, ...]
  t.jsonb :inquiry_config, default: {} # API endpoint, auth method, timeout
  t.jsonb :payment_config, default: {} # settlement terms, cutoff times
  t.string :status, default: "active"  # active | maintenance | inactive
  t.timestamps
end
add_index :utility_billers, :code, unique: true

# Cooperative-level biller activation and commission
create_table "utility_coop_biller_configs" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.references :biller, null: false, foreign_key: { to_table: :utility_billers }
  t.boolean :active, default: false
  t.integer :commission_cents   # per-transaction commission (overrides network default)
  t.jsonb :config_overrides, default: {}  # coop-specific config
  t.timestamps
end
add_index :utility_coop_biller_configs, [:cooperative_id, :biller_id], unique: true, name: "idx_coop_biller_unique"

# Bill payment record
create_table "utility_bill_payments" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.references :member, null: false, foreign_key: true
  t.references :biller, null: false, foreign_key: { to_table: :utility_billers }
  t.references :processed_by, foreign_key: { to_table: :users }  # teller (null if portal)
  t.references :cash_session, foreign_key: { to_table: :treasury_cash_sessions }  # null if portal
  t.string :biller_account_number, null: false
  t.string :biller_account_name  # from inquiry response
  t.integer :amount_cents, null: false
  t.integer :fee_cents, default: 0
  t.integer :commission_cents, default: 0  # coop's commission on this payment
  t.string :funding_source, null: false     # cash | savings_account | share_capital
  t.references :funding_account, polymorphic: true  # the savings account, etc.
  t.string :reference_number, null: false   # SIR-MER-20260716-00001
  t.string :status, null: false, default: "pending"  # pending | submitted | confirmed | failed | reversed
  t.string :external_reference  # biller's confirmation code
  t.datetime :paid_at
  t.datetime :confirmed_at
  t.text :failure_reason
  t.timestamps
end
add_index :utility_bill_payments, :reference_number, unique: true
add_index :utility_bill_payments, [:cooperative_id, :status]
add_index :utility_bill_payments, [:biller_id, :biller_account_number, :paid_at], name: "idx_payments_biller_account_date"

# Auto-pay enrollment
create_table "utility_auto_pay_enrollments" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.references :member, null: false, foreign_key: true
  t.references :biller, null: false, foreign_key: { to_table: :utility_billers }
  t.string :biller_account_number, null: false
  t.string :biller_account_name
  t.references :funding_account, polymorphic: true, null: false  # savings account
  t.integer :monthly_max_cents  # safety cap
  t.integer :days_before_due, default: 3
  t.string :status, default: "active"  # active | paused | suspended | cancelled
  t.datetime :last_paid_at
  t.datetime :next_payment_at
  t.integer :consecutive_failures, default: 0
  t.timestamps
end
add_index :utility_auto_pay_enrollments, [:cooperative_id, :member_id, :biller_id, :biller_account_number], unique: true, name: "idx_auto_pay_unique"

# Auto-pay execution log
create_table "utility_auto_pay_executions" do |t|
  t.references :auto_pay_enrollment, null: false, foreign_key: { to_table: :utility_auto_pay_enrollments }
  t.references :bill_payment, foreign_key: { to_table: :utility_bill_payments }
  t.date :scheduled_date
  t.string :status, default: "pending"  # pending | executed | skipped | failed
  t.integer :amount_cents
  t.text :failure_reason
  t.timestamps
end

# Biller settlement records
create_table "utility_settlements" do |t|
  t.references :biller, null: false, foreign_key: { to_table: :utility_billers }
  t.date :settlement_date, null: false
  t.integer :total_amount_cents, null: false, default: 0
  t.integer :total_fees_cents, null: false, default: 0
  t.integer :total_commission_cents, null: false, default: 0
  t.integer :net_remittance_cents, null: false, default: 0
  t.integer :transaction_count, null: false, default: 0
  t.string :status, default: "pending"  # pending | settled | reconciled | disputed
  t.datetime :settled_at
  t.timestamps
end
add_index :utility_settlements, [:biller_id, :settlement_date], unique: true, name: "idx_biller_settlement_date"
```

### 5.3 Biller Integration Pattern

```
┌──────────────────────────────────────────────────────────────────┐
│                    Biller Integration Adapter                      │
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │
│  │ Meralco      │  │ Maynilad    │  │ PLDT        │  ...          │
│  │ Adapter      │  │ Adapter     │  │ Adapter     │               │
│  └──────┬───────┘  └──────┬──────┘  └──────┬──────┘               │
│         │                 │                 │                      │
│  ┌──────┴─────────────────┴─────────────────┴────────┐            │
│  │         Base Biller Adapter (interface)            │            │
│  │  + inquire(biller_account) → BillInquiryResult     │            │
│  │  + pay(bill_payment) → PaymentResult               │            │
│  │  + confirm(transaction_id) → ConfirmationResult    │            │
│  └──────────────────────┬─────────────────────────────┘            │
│                         │                                          │
│  ┌──────────────────────┴─────────────────────────────┐            │
│  │         HTTP Client (faraday / net/http)            │            │
│  │         With retry, timeout, and circuit breaker    │            │
│  └────────────────────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────────────┘
```

Each biller adapter implements:

```ruby
class Utility::Adapters::MeralcoAdapter < Utility::Adapters::BaseAdapter
  def inquire(account_number:)
    # HTTP POST to Meralco inquiry API
    # Return { account_name:, amount_due:, due_date:, status: }
  end

  def pay(account_number:, amount_cents:, reference_number:)
    # HTTP POST to Meralco payment API
    # Return { external_reference:, status: }
  end

  def confirm(external_reference:)
    # HTTP GET to check payment status
    # Return { status:, confirmed_at: }
  end
end
```

### 5.4 Payment Lifecycle

```
1. INQUIRY     → Member provides biller + account number
                → Adapter.inquire(account_number)
                → Returns amount_due, due_date, account_name
                → Displayed to member for confirmation

2. EXECUTION   → Member confirms payment
                → Transaction wraps:
                    a. Debit source (cash/savings)
                    b. Credit utility_clearing account
                    c. Create BillPayment record (status: pending)
                → Enqueue confirmation job

3. SUBMISSION  → Adapter.pay(account_number, amount, reference)
                → On success: status → submitted
                → On failure: status → failed → initiate reversal

4. CONFIRMATION → Adapter.confirm(external_reference)
                  → Runs async (5min, 30min, 2hr, 24hr)
                  → On confirmed: status → confirmed
                  → On failed after retries: status → failed → reverse

5. SETTLEMENT  → Daily: net all confirmed payments per biller
                → Generate settlement report
                → Transfer net amount to biller
                → Credit cooperative commissions
```

### 5.5 Biller Clearing Account Model

```
Accounting entries for a PHP 1,245 Meralco payment:

DEBIT   Cash on Hand (or Member Savings)             PHP 1,245.00
CREDIT  Utility Clearing — Meralco                   PHP 1,245.00
  (Entry: payment received from member)

--- On settlement to Meralco ---

DEBIT   Utility Clearing — Meralco                   PHP 1,220.00
CREDIT  Settlement Account — Meralco                 PHP 1,220.00
  (Entry: PHP 1,245 - PHP 25 fee remitted to Meralco)

DEBIT   Utility Clearing — Meralco                   PHP 25.00
CREDIT  Commission Income — Bill Payment             PHP 25.00
  (Entry: cooperative retains commission)
```

### 5.6 Jobs

| Job | Trigger | Description |
|-----|---------|-------------|
| `Utility::BillPaymentConfirmationJob` | 5 min after payment | Check biller confirmation status |
| `Utility::DailyAutoPayCheckJob` | Cron (daily, 6 AM) | Find all auto-pay enrollments due today |
| `Utility::ExecuteAutoPayJob` | Per enrollment | Execute single auto-pay payment |
| `Utility::AutoPayRetryJob` | 3 days after failure | Retry failed auto-payments |
| `Utility::BillerSettlementJob` | Cron (daily, midnight) | Calculate and execute biller settlement |
| `Utility::BillerReconciliationJob` | After settlement | Match coop records vs biller records |

### 5.7 Routes

```ruby
# config/routes.rb
namespace :utility do
  # Biller directory (visible to all authenticated users)
  resources :billers, only: [:index, :show]

  # Bill inquiry and payment
  resource :bill_inquiry, only: [:new, :create]
  resources :payments, only: [:index, :show, :create] do
    collection do
      post :preview
      get :receipt
    end
  end

  # Auto-pay
  resources :auto_pay_enrollments do
    member do
      post :pause
      post :resume
      post :cancel
    end
  end

  # Settlement (admin only)
  resources :settlements, only: [:index, :show]
end

# Management routes (coop admin)
namespace :management do
  namespace :utility do
    resources :biller_configs, only: [:index, :edit, :update]  # enable/disable billers
    resources :payments, only: [:index, :show]                  # view all payments
    resources :settlements, only: [:index, :show]               # view settlement reports
    resources :auto_pay_enrollments, only: [:index, :show]      # view enrollments
  end
end

# Portal routes (member-facing)
namespace :portal do
  resources :utility_payments, only: [:index, :new, :create, :show]
  resources :auto_pay, only: [:index, :new, :create, :edit, :update, :destroy]
end
```

---

## 6. Biller Onboarding

### 6.1 Biller Integration Tiers

| Tier | Description | Examples | Integration |
|------|-------------|----------|-------------|
| **Tier 1: Direct API** | Billers with public payment APIs | Meralco (via Bayad Center or direct), PLDT, Globe | Real-time inquiry + payment |
| **Tier 2: Batch File** | Billers accepting batch payment files | Smaller utilities, LGUs, water districts | Daily CSV/EDI file upload |
| **Tier 3: Manual** | Billers requiring manual remittance | Very small billers | Cooperative remits manually; system tracks as paid |
| **Tier 4: Aggregator** | Via existing bill payment aggregators | Bayad Center, EC Pay, 7-Eleven CLIQQ | Single integration to aggregator's API |

### 6.2 Priority Biller List

| Biller | Category | Tier | Coverage |
|--------|----------|------|----------|
| Meralco | Electricity | 1 | Metro Manila, Luzon |
| Manila Water | Water | 1 | Metro Manila East |
| Maynilad | Water | 1 | Metro Manila West |
| PLDT Home | Telecom | 1 | Nationwide |
| Globe Telecom | Telecom | 1 | Nationwide |
| Smart Communications | Telecom | 1 | Nationwide |
| Sky Cable | Cable/Internet | 1 | Metro Manila |
| Converge ICT | Internet | 1 | Nationwide |
| National Water Districts | Water | 2 | Provincial |
| Local Electric Coops (electric coops) | Electricity | 2 | Provincial |
| Government (SSS, PhilHealth, Pag-IBIG) | Government | 1 via aggregator | Nationwide |

---

## 7. Cross-Cooperative Bill Payment

A member of Coop A can pay a bill at Coop B's teller counter.

### Flow

```
1. Member presents biller account at Coop B teller
2. Teller enters member lookup: name + cooperative (or member ID from any network coop)
3. System validates member exists in network (via network directory)
4. Teller processes payment
5. Journal entries:
   Coop B:
     DEBIT  Cash on Hand (Coop B)                     PHP 1,245.00
     CREDIT Intercoop Payable — Coop A (Clearing)     PHP 1,220.00
     CREDIT Commission Income (Coop B)                PHP 25.00
   Coop A (via settlement):
     DEBIT  Intercoop Receivable — Coop B (Clearing)  PHP 1,220.00
     CREDIT Utility Clearing — Meralco                PHP 1,220.00

6. Network settlement: Coop B owes Coop A PHP 1,220
7. Daily net settlement handles it (see Settlement PRD)
8. Coop A's Meralco clearing account gets credited
9. Coop A settles with Meralco in its batch
```

This creates a compelling reason for cooperatives to join the network: their members can pay bills anywhere.

---

## 8. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | Bill inquiry response time: < 3 seconds (P95) | Includes biller API latency |
| NFR-02 | One-time payment execution: < 10 seconds end-to-end | Portal; teller is instant |
| NFR-03 | Auto-pay batch: 10,000 enrollments processed in < 30 minutes | Daily batch |
| NFR-04 | Biller API timeout: 10 seconds; circuit breaker after 5 failures | 30-second cooldown |
| NFR-05 | Payment confirmation: > 99.5% within 24 hours | Async confirmation |
| NFR-06 | Settlement accuracy: 100% — every centavo accounted for | Design + reconciliation |
| NFR-07 | Audit trail: every payment, every state transition, immutable | Append-only |
| NFR-08 | Receipt retention: 7 years | Database or blob storage |

---

## 9. Security & Compliance

| Concern | Mitigation |
|---------|-----------|
| **Member account number exposure** | Biller account numbers stored encrypted at rest; masked in logs and UI (e.g., "****-****-7890") |
| **Payment replay** | Idempotency key on each payment; unique reference number |
| **Unauthorized auto-pay enrollment** | MFA required for portal enrollment; signed authorization form for teller enrollment |
| **Auto-pay runaway** | Monthly safety cap per enrollment; daily maximum per member |
| **Biller impersonation** | Biller adapters verify biller SSL certificates; IP whitelisting where possible |
| **Data privacy** | Payment records are PII; access limited to member, authorized tellers, and compliance |
| **AML monitoring** | Bill payments monitored for suspicious patterns (structuring, rapid payments) |
| **BSP regulations** | Bill payment may require BSP registration as a payment system; outsource to licensed aggregator (Bayad Center) for Tier 1 billers |

---

## 10. Implementation Phases

### Phase 1: Core Bill Payment Engine (4 weeks)

- Biller directory model and admin CRUD
- Bill payment model and state machine
- Base biller adapter interface + Meralco adapter (Tier 1)
- Bill inquiry and payment services
- Journal entry integration (clearing account)
- Teller payment UI (management interface)

### Phase 2: Member Portal & Receipts (3 weeks)

- Portal bill payment (inquiry → confirm → pay)
- Receipt generation (PDF + SMS + email)
- Payment history in portal
- Transaction fees and commission tracking

### Phase 3: Auto-Pay (3 weeks)

- Auto-pay enrollment model and UI
- Daily auto-pay execution job
- Retry and suspension logic
- Notifications (before, after, failure)
- Auto-pay management in portal

### Phase 4: More Billers (ongoing)

- Maynilad, Manila Water (Tier 1)
- PLDT, Globe (Tier 1)
- Government agencies (via aggregator, Tier 4)
- Batch file processing for Tier 2 billers
- Biller onboarding toolkit and documentation

### Phase 5: Cross-Coop Bill Payment (3 weeks)

- Bill payment across cooperative branches
- Inter-coop settlement integration for bill payments
- Member lookup across network (by any identifier)
- Cross-coop commission splitting

### Phase 6: Settlement & Reconciliation (2 weeks)

- Biller settlement engine (daily batch)
- Settlement reports per biller per coop
- Auto-reconciliation (network records vs biller records)
- Discrepancy dashboard

---

## 11. Revenue Model

| Fee | Amount | Paid By | Recipient |
|-----|--------|---------|-----------|
| Transaction fee | PHP 5–25 per payment | Cooperative (from commission) | Sirib network |
| Biller onboarding | PHP 50,000–200,000 one-time | Biller | Sirib network |
| Commission | PHP 5–50 per payment (varies by biller) | Biller | Cooperative (split with Sirib) |
| Auto-pay premium | PHP 10/month per enrollment | Member (or waived) | Cooperative |
| Settlement report | PHP 500/month | Cooperative | Sirib network |

---

## 12. Success Criteria

- [ ] Member can pay a Meralco bill from teller counter and receive receipt
- [ ] Member can pay a Meralco bill from portal using savings account
- [ ] Member can set up auto-pay and it executes on schedule
- [ ] Auto-pay retries on failure and suspends after max retries
- [ ] Member of Coop A can pay bill at Coop B teller
- [ ] Payment is idempotent — same reference cannot be paid twice
- [ ] All bill payments are auditable (who, when, where, what)
- [ ] Daily settlement to Meralco balances to zero
- [ ] Commission is correctly calculated and credited to cooperative
- [ ] 5+ billers integrated and operational
- [ ] No security findings related to bill payment

---

## 13. Open Questions

1. **Build adapters or use an aggregator?** Bayad Center and EC Pay already have bill payment APIs with most billers. A single Bayad Center integration gives us 50+ billers. Recommended: use aggregator for breadth, add direct integrations for high-volume billers (Meralco, PLDT).
2. **Clearing account structure?** One clearing account per biller? Per aggregator? Per cooperative? Recommend: one clearing account per biller per cooperative for clean reconciliation.
3. **Auto-pay legal basis?** Does auto-pay require a separate authorization form under BSP regulations? Yes — needs legal review.
4. **Failed payment liability?** If auto-pay fails and member incurs a late fee, who is liable? Sirib should have a no-liability clause with automated reconnection where supported.
5. **Commission sharing for cross-coop payments?** If Coop A's member pays at Coop B, who gets the commission? Recommend: split — Coop B gets service fee for handling the transaction; Coop A gets membership commission. Ratio: 70/30 or configurable.
6. **Settlement speed?** T+0 (same day), T+1, or T+3? Most billers expect T+1. Recommend T+1 for standard, T+0 premium for additional fee.
7. **Float income?** Payments collected from members are held until settlement date. The cooperative earns interest on the float. This should be modeled as a revenue stream.
