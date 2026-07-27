# PRD: Inter-Cooperative Settlement & Clearing

> **Status:** Draft · **Owner:** CTO · **Version:** 1.0
> **Dependency:** Inter-Cooperative Transfers (Phase 1)
> **Target:** Phase 2 — Net settlement infrastructure

---

## 1. Executive Summary

Individual inter-coop transfers create bilateral obligations between cooperatives. Cooperative A owes Cooperative B PHP 50,000 at end of day; Cooperative B owes Cooperative C PHP 30,000. Without a settlement layer, each pair must settle individually — inefficient, expensive, and error-prone.

This PRD defines the clearing house mechanism that nets obligations between all cooperatives on the Sirib network and settles the net position, typically through a central settlement account or prefunded ledger.

---

## 2. Why This Matters

- **Scale requires netting.** With 10+ cooperatives and thousands of transfers daily, bilateral settlement is unsustainable.
- **Liquidity efficiency.** Netting reduces settlement amounts by 60-80% vs gross settlement.
- **Regulatory expectation.** Most payment system regulators require a clearing and settlement arrangement.
- **Revenue model.** The clearing house can charge a per-transaction or monthly fee, creating the network's revenue stream.
- **Foundation for more products.** Settlement is the plumbing that enables scheduled payments, recurring transfers, and future financial products.

---

## 3. Clearing Model

### 3.1 Net Settlement Cycle

```
End of Business Day (EOD)
  ↓
1. CUT OFF — All transfers up to 23:59:59 are final
2. NETTING — Calculate net position per cooperative
   - Coop A sent PHP 100,000 to Coop B
   - Coop A sent PHP 20,000 to Coop C
   - Coop B sent PHP 30,000 to Coop A
   → Coop A net: -(100,000 + 20,000) + 30,000 = -90,000 (debtor)
   → Coop B net: +100,000 - 30,000 = +70,000 (creditor)
   → Coop C net: +20,000 (creditor)
3. SETTLEMENT — Debtor cooperatives pay into settlement account
4. DISTRIBUTION — Creditor cooperatives receive from settlement account
5. RECONCILIATION — Each coop reconciles its general ledger
```

### 3.2 Settlement Account Model

```
┌─────────────────────────────────────────────────────────────┐
│                   Sirib Clearing House                       │
│                                                              │
│  Settlement Account (held at a commercial bank or BSP)       │
│  ┌──────────────────────────────────────────────────┐       │
│  │  Coop A: PHP 500,000 (prefunded buffer)          │       │
│  │  Coop B: PHP 500,000 (prefunded buffer)          │       │
│  │  Coop C: PHP 500,000 (prefunded buffer)          │       │
│  │  ─────────────────────────────────────────       │       │
│  │  Total: PHP 1,500,000                            │       │
│  └──────────────────────────────────────────────────┘       │
│                                                              │
│  Daily Settlement:                                           │
│  ┌──────────────────────────────────────────────────┐       │
│  │  Coop A owes PHP 90,000 → debited from buffer    │       │
│  │  Coop B receives PHP 70,000 → credited to buffer │       │
│  │  Coop C receives PHP 20,000 → credited to buffer │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 Alternative: No Prefund (Trust-Based)

For smaller or trusted cooperatives, settlement can be trust-based:
- Net position is recorded but not settled in cash daily
- Settlement happens weekly or when a threshold is exceeded (e.g., PHP 1M)
- Backed by cooperative guarantee or insurance pool

---

## 4. Functional Requirements

### 4.1 Cutoff and Netting

| ID | Requirement | Priority |
|----|-------------|----------|
| STL-01 | System automatically cuts off at configurable time (default 23:59 PHT) | P0 |
| STL-02 | All transfers before cutoff are included in settlement cycle | P0 |
| STL-03 | Netting calculates bilateral and multilateral net positions | P0 |
| STL-04 | Settlement report is generated and available by 08:00 next day | P0 |
| STL-05 | Cooperative admins can view their settlement position in real-time (intraday) | P1 |
| STL-06 | Settlement cycle can be manually triggered for testing and recovery | P1 |

### 4.2 Settlement Execution

| ID | Requirement | Priority |
|----|-------------|----------|
| STL-07 | Debtor cooperatives are notified of amount due by 08:00 | P0 |
| STL-08 | Settlement must be completed by 12:00 (T+0 or T+1) | P0 |
| STL-09 | Settlement can be via: (a) prefunded buffer deduction, (b) bank transfer, (c) internal ledger entry | P0 |
| STL-10 | Failed settlement (insufficient buffer, bank delay) triggers escalation | P0 |
| STL-11 | Escalated settlements go to manual resolution with admin alert | P1 |
| STL-12 | Late settlement incurs penalty fee (configurable) | P2 |

### 4.3 Reconciliation

| ID | Requirement | Priority |
|----|-------------|----------|
| STL-13 | Each cooperative receives a settlement statement with all transfers listed | P0 |
| STL-14 | Cooperative can reconcile transfers against their internal records | P0 |
| STL-15 | Discrepancy detection: system flags mismatches between coop records and network records | P0 |
| STL-16 | Cooperative can file a dispute on a specific transfer within 7 days | P1 |
| STL-17 | Disputed transfers are resolved via admin interface; resolution updates settlement | P1 |

### 4.4 Liquidity Management

| ID | Requirement | Priority |
|----|-------------|----------|
| STL-18 | Cooperative can top up prefunded buffer at any time | P0 |
| STL-19 | Low-buffer warning sent when balance falls below configurable threshold | P0 |
| STL-20 | Cooperative can set auto-top-up rules (threshold → amount) | P2 |
| STL-21 | Cooperative can view historical settlement positions and buffer utilization | P1 |
| STL-22 | System calculates minimum recommended buffer based on average daily net flow | P2 |

---

## 5. Technical Architecture

### 5.1 Settlement Engine

```
┌─────────────────────────────────────────────────────┐
│              Settlement Engine (Daily Job)            │
│                                                       │
│  1. Lock settlement window (no new transfers)         │
│  2. Query all transfers between cutoff boundaries     │
│  3. Group by (source_coop, destination_coop)          │
│  4. Calculate bilateral net: SUM(sent) - SUM(received)│
│  5. Calculate multilateral net: SUM(bilateral nets)   │
│  6. Generate settlement instructions                  │
│  7. Execute settlement (deduct buffer / create txns)  │
│  8. Generate settlement reports                       │
│  9. Send notifications                                │
└─────────────────────────────────────────────────────┘
```

### 5.2 Data Model Additions

```ruby
# Settlement cycle record
create_table "intercoop_settlement_cycles" do |t|
  t.date :settlement_date, null: false
  t.string :status, null: false  # pending | netting | settling | settled | disputed
  t.datetime :cutoff_at
  t.datetime :settled_at
  t.timestamps
end
add_index :intercoop_settlement_cycles, :settlement_date, unique: true

# Net position per cooperative per cycle
create_table "intercoop_net_positions" do |t|
  t.references :settlement_cycle, null: false
  t.references :cooperative, null: false
  t.integer :sent_cents, null: false, default: 0
  t.integer :received_cents, null: false, default: 0
  t.integer :net_cents, null: false  # negative = debtor, positive = creditor
  t.string :status, null: false      # pending | settled | disputed
  t.timestamps
end
add_index :intercoop_net_positions, [:settlement_cycle_id, :cooperative_id], unique: true, name: "idx_net_positions_unique"

# Settlement account (prefunded buffer per cooperative)
create_table "intercoop_settlement_accounts" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.integer :buffer_cents, null: false, default: 0
  t.integer :minimum_buffer_cents, null: false, default: 0
  t.string :funding_source  # bank account reference for manual top-up
  t.timestamps
end

# Settlement transaction (individual ledger entry)
create_table "intercoop_settlement_entries" do |t|
  t.references :settlement_cycle, null: false
  t.references :cooperative, null: false
  t.string :entry_type, null: false  # debit | credit | fee
  t.integer :amount_cents, null: false
  t.string :status, null: false
  t.string :reference
  t.timestamps
end
```

### 5.3 Jobs

| Job | Trigger | Description |
|-----|---------|-------------|
| `SettlementCutoffJob` | Cron (23:59) | Locks transfer window for the day |
| `NettingCalculationJob` | After cutoff | Calculates all net positions |
| `SettlementExecutionJob` | After netting | Deducts/credits settlement accounts |
| `LowBufferWarningJob` | After settlement | Checks buffers against thresholds |
| `SettlementReportJob` | After settlement | Generates PDF/CSV reports per coop |
| `SettlementDisputeResolutionJob` | On dispute | Recalculates affected positions |

---

## 6. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | Settlement calculation for 100 coops, 100K daily transfers: < 5 minutes | P95 |
| NFR-02 | Settlement window: maximum 30 minutes from cutoff to settlement executed | P99 |
| NFR-03 | Zero tolerance for arithmetic errors in netting | Design + tests |
| NFR-04 | Settlement data must be auditable for 10+ years | Immutable records |
| NFR-05 | System must survive the settlement window without downtime | High-availability design |

---

## 7. Settlement Window Protection

The settlement window is the most critical time in the system. Design for safety:

```ruby
class SettlementExecutionJob
  def perform(cycle)
    SettlementCycle.transaction do
      # 1. Lock the settlement cycle (prevent concurrent execution)
      cycle = SettlementCycle.lock("FOR UPDATE").find(cycle.id)
      raise "Already settled" unless cycle.status == "netting"

      # 2. Lock all settlement accounts involved
      accounts = IntercoopSettlementAccount
                   .lock("FOR UPDATE")
                   .where(cooperative_id: cycle.net_positions.pluck(:cooperative_id))

      # 3. Verify all accounts have sufficient buffers (for debtors)
      cycle.net_positions.debtor.each do |position|
        account = accounts.find { |a| a.cooperative_id == position.cooperative_id }
        raise "Insufficient buffer for #{position.cooperative.name}" if account.buffer_cents < position.net_cents.abs
      end

      # 4. Execute settlement entries atomically
      cycle.execute_settlement!

      # 5. Release locks — transaction commits
    end
  end
end
```

---

## 8. Fee Structure

| Fee | Description | Amount |
|-----|-------------|--------|
| Clearing fee | Per transfer processed through clearing | PHP 1.00 |
| Settlement fee | Per settlement cycle | PHP 50.00 per cooperative |
| Late settlement penalty | Per day late | 0.1% of owed amount |
| Dispute resolution fee | Per disputed transfer | PHP 100.00 |

---

## 9. Regulatory Considerations

| Concern | Approach |
|---------|----------|
| Is Sirib a payment system? | Likely yes — may need BSP (or equivalent) registration as a payment system operator |
| Is Sirib a bank? | No — settlement accounts at commercial banks, not deposit-taking |
| AML/CFT obligations | Each cooperative performs KYC; Sirib monitors cross-coop patterns |
| Data privacy | Transfer data shared between coops with member consent; network node holds transaction records but not personally identifiable information beyond what's needed for routing |
| Settlement finality | Settlement is final at T+1 12:00; no chargebacks after settlement |

---

## 10. Implementation Phases

### Phase 1: Settlement Core (3 weeks)

- Settlement cycle model and state machine
- Netting calculation algorithm
- Settlement execution against prefunded buffers
- Settlement report generation

### Phase 2: Liquidity Management (2 weeks)

- Settlement account management
- Buffer top-up workflow
- Low-buffer alerts and auto-top-up
- Historical position dashboard

### Phase 3: Reconciliation & Disputes (2 weeks)

- Reconciliation statement generation per coop
- Discrepancy detection
- Dispute filing and resolution workflow
- Manual settlement interface for edge cases

### Phase 4: Reporting & Compliance (2 weeks)

- Regulatory reports (daily transaction volumes, settlement amounts, net positions)
- Audit log for all settlement actions
- Integration with coop's general ledger

---

## 11. Success Criteria

- [ ] Netting calculation verified correct against manual calculation for 10+ scenarios
- [ ] Settlement executes correctly for debtor and creditor cooperatives
- [ ] Low-buffer warnings fire at correct thresholds
- [ ] Discrepancy detection catches all simulated mismatches
- [ ] Settlement can be reversed (rare, for disaster recovery)
- [ ] All settlement activity fully auditable
- [ ] Daily settlement cycle runs unattended for 30 days without error

---

## 12. Open Questions

1. **Settlement bank partner?** Need a commercial bank to hold the master settlement account. Who?
2. **Prefund requirement?** Minimum buffer per cooperative? Based on 2x average daily net?
3. **Default management?** What happens if a coop cannot settle? Suspension? Insurance pool?
4. **Regulatory timeline?** How long to register as a payment system operator?
5. **Multi-currency?** Start PHP-only; when to add other currencies?
