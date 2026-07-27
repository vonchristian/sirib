# PRD: Inter-Cooperative Member Transfers

> **Status:** Draft · **Owner:** CTO · **Version:** 1.0
> **Dependency:** Core Banking Foundation (Phase 0)
> **Target:** Phase 1 — First network-connected feature

---

## 1. Executive Summary

The first network feature: a member of Cooperative A can transfer money to a member of Cooperative B. The transfer is initiated from either cooperative's banking interface, routed through a Sirib network node, and settled between the two cooperatives.

This is the "hello world" of inter-cooperative finance. It proves the network concept, builds the routing infrastructure, and delivers immediate member value.

---

## 2. Why This Matters

- **Network effects start here.** A transfer between coops is the atomic unit of interconnection. Without it, nothing else matters.
- **Immediate member value.** Most cooperative members have family or business partners in other cooperatives. Inter-coop transfers save them fees from banks and remittance services.
- **Proof of network infrastructure.** This forces us to build: cooperative identity, routing, settlement, reconciliation, error handling.
- **Regulatory pattern.** Most jurisdictions permit P2P transfers between regulated financial institutions. This establishes the compliance pattern for everything else.

---

## 3. User Stories

### Member Flow

```
1. Maria (Coop A member) logs into her coop's member portal
2. Selects "Send Money to Another Cooperative"
3. Searches for "Juan" in Coop B (by name, member number, or phone)
4. Enters amount: PHP 5,000
5. Confirms with MFA
6. Maria sees: "Sent! Juan will receive PHP 4,975 (PHP 25 fee)"
7. Juan receives SMS/email notification
8. Juan logs into his Coop B portal → sees new balance
```

### Teller/Admin Flow

```
1. Teller selects "Inter-Cooperative Transfer"
2. Enters destination coop + member identifier
3. System shows member name (confirmed) and fee
4. Teller collects cash or debits member's savings account
5. Transfer submitted → pending → confirmed
```

---

## 4. Functional Requirements

### 4.1 Member Discovery

| ID | Requirement | Priority |
|----|-------------|----------|
| DISC-01 | Members can search for other members by name, member number, or phone number across the network | P0 |
| DISC-02 | Search returns basic info (name, cooperative name) — no financial details | P0 |
| DISC-03 | Member must consent to being discoverable via their own cooperative's settings | P1 |
| DISC-04 | Search does not reveal whether the member has an account or balance | P0 |
| DISC-05 | Cooperative can disable outbound searches (opt-out from network) | P0 |

### 4.2 Transfer Initiation

| ID | Requirement | Priority |
|----|-------------|----------|
| XFR-01 | Sender selects source account (savings, share capital, or cash at teller) | P0 |
| XFR-02 | Sender enters amount in PHP | P0 |
| XFR-03 | System calculates and displays fee before confirmation | P0 |
| XFR-04 | Sender confirms with MFA (if member portal) or teller approval (if over-the-counter) | P0 |
| XFR-05 | Transfer is idempotent — duplicate submission does not double-execute | P0 |
| XFR-06 | Sender receives confirmation with transaction reference | P0 |
| XFR-07 | Sender can cancel within 30 seconds (soft hold) | P2 |

### 4.3 Transfer Routing

| ID | Requirement | Priority |
|----|-------------|----------|
| RTE-01 | Transfer is routed to the correct cooperative via a cooperative routing table | P0 |
| RTE-02 | Routing table is maintained centrally and cached locally | P0 |
| RTE-03 | If destination cooperative is offline, transfer is queued with retry | P0 |
| RTE-04 | Maximum retry: 3 attempts over 15 minutes, then auto-reverse | P0 |
| RTE-05 | Destination cooperative validates the receiving member exists before accepting | P0 |
| RTE-06 | Transfer status is trackable end-to-end (pending → routed → credited → settled) | P0 |

### 4.4 Fee Model

| ID | Requirement | Priority |
|----|-------------|----------|
| FEE-01 | Sending cooperative sets its own outbound transfer fee | P1 |
| FEE-02 | Receiving cooperative receives a settlement fee (set by receiving coop) | P1 |
| FEE-03 | Network operator (Sirib) takes a transaction fee (configurable, per-coop or flat) | P1 |
| FEE-04 | All fees are transparently displayed before transfer confirmation | P0 |
| FEE-05 | Fee structure is versioned and auditable | P2 |

### 4.5 Error Handling

| ID | Requirement | Priority |
|----|-------------|----------|
| ERR-01 | Invalid member identifier → clear error: "Member not found in Cooperative B" | P0 |
| ERR-02 | Insufficient balance → error before submission | P0 |
| ERR-03 | Destination cooperative rejects → auto-reverse within 5 minutes | P0 |
| ERR-04 | Network timeout → transfer marked as "pending" with manual reconciliation path | P0 |
| ERR-05 | Duplicate idempotency key → return success (already processed) | P0 |

---

## 5. Technical Architecture

### 5.1 Network Topology

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Cooperative A   │     │  Cooperative B   │     │  Cooperative C   │
│  (Sirib Rails)   │     │  (Sirib Rails)   │     │  (Sirib Rails)   │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │   Sirib Network Node     │
                    │  (Routing + Settlement)  │
                    │  (Message Queue Bridge)  │
                    └─────────────────────────┘
```

### 5.2 Key Components

| Component | Description | Technology |
|-----------|-------------|------------|
| **Network Node** | Central router for inter-coop messages | Separate Rails service or gem |
| **Cooperative Router** | Routes outbound transfers to the correct coop | `Intercoop::Router` service |
| **Transfer Service** | Orchestrates the transfer lifecycle | `Intercoop::TransferService` |
| **Message Queue** | Async communication between coops | Solid Queue or RabbitMQ |
| **Routing Table** | Cooperative discovery + address registry | Database table, synced to each instance |
| **Idempotency Guard** | Prevents duplicate transfers | `IdempotencyKey` model (exists) |

### 5.3 Transfer Lifecycle

```
1. CREATE       → Sender initiates transfer → status: pending
2. RESERVE      → Source account debited (hold) → status: reserved
3. ROUTE        → Network node receives message → status: routing
4. DELIVER      → Destination coop receives → status: delivering
5. CREDIT       → Recipient account credited → status: credited
6. CONFIRM      → Source coop confirmed → status: completed
7. FAIL → REVERSE → If any step fails, release hold → status: reversed
```

### 5.4 API Contract (Between Coop Instances)

```
POST /intercoop/transfers
{
  transfer_id: "uuid",
  source_coop_id: "coop_a",
  destination_member_id: "member_123",
  amount_cents: 500000,
  currency: "PHP",
  fee_cents: 2500,
  idempotency_key: "uuid-v4",
  signed_digest: "hmac-sha256(…)",
  timestamp: "2026-07-16T10:00:00Z"
}

Response:
{
  status: "accepted" | "rejected" | "pending",
  transfer_id: "uuid",
  destination_member_name: "Juan Dela Cruz",
  settled_at: "2026-07-16T10:00:05Z"
}
```

---

## 6. Data Model Additions

```ruby
# Cooperative identity & routing
create_table "intercoop_routes" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.string :host, null: false        # coop.sirib.ph
  t.string :routing_number, null: false  # unique coop routing ID
  t.string :status, default: "active"    # active | inactive | suspended
  t.timestamps
end

# Cross-cooperative transfers
create_table "intercoop_transfers" do |t|
  t.references :source_cooperative, null: false
  t.references :destination_cooperative, null: false
  t.string :source_member_identifier
  t.string :destination_member_identifier
  t.integer :amount_cents, null: false
  t.integer :fee_cents, null: false, default: 0
  t.string :status, null: false       # see lifecycle above
  t.string :idempotency_key, null: false
  t.text :error_message
  t.datetime :completed_at
  t.timestamps
end
add_index :intercoop_transfers, :idempotency_key, unique: true

# Member consent for network discovery
create_table "intercoop_member_consents" do |t|
  t.references :member, null: false, foreign_key: true
  t.boolean :discoverable, default: false
  t.boolean :inbound_enabled, default: true
  t.datetime :consented_at
  t.timestamps
end
```

---

## 7. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | Transfer initiation → confirmation: < 30s end-to-end | P95 |
| NFR-02 | Transfer failure detection: < 5s | Timeout |
| NFR-03 | Network node uptime: 99.9% | Monthly |
| NFR-04 | Idempotency: 100% — zero double-executions | Design + test |
| NFR-05 | Audit trail: every state transition logged | Immutable |

---

## 8. Security Considerations

| Concern | Mitigation |
|---------|-----------|
| Impersonation of a cooperative | HMAC-signed requests with rotating keys |
| Replay attack | Timestamp + nonce + idempotency key |
| Member enumeration | Search returns minimal info; rate-limited |
| Man-in-the-middle | All inter-coop traffic over HTTPS + mutual TLS |
| Double credit | Idempotency key + unique constraint on `intercoop_transfers` |
| Destination coop goes rogue | Daily reconciliation + dispute process |

---

## 9. Implementation Phases

### Phase 1: Foundation (3 weeks)

- Cooperative identity and routing table
- `Intercoop::Router` and `Intercoop::TransferService`
- Inter-coop API contract and HMAC signing
- Idempotency integration
- Transfer lifecycle model + state machine

### Phase 2: Member Discovery (1 week)

- Member search across cooperatives
- Consent management
- Rate limiting on lookups

### Phase 3: Portal Integration (2 weeks)

- Member portal: "Send to Another Cooperative" form
- Teller interface: inter-coop transfer from cash/savings
- Transaction history display
- Notification (SMS/email) on send and receive

### Phase 4: Reconciliation (2 weeks)

- Daily settlement report generation
- Discrepancy detection and alerting
- Manual reconciliation interface for admins
- Fee settlement between cooperatives

---

## 10. Success Criteria

- [ ] Member of Coop A can transfer PHP to member of Coop B end-to-end
- [ ] Transfer completes in < 30s under normal conditions
- [ ] Duplicate submission is safely handled (idempotent)
- [ ] Failed transfers are automatically reversed within 5 minutes
- [ ] All state transitions are audited
- [ ] Daily reconciliation reports balance to zero
- [ ] Test coverage: transfer creation, routing, delivery, reversal, reconciliation
- [ ] Playwright E2E: happy path, validation, edge cases, error scenarios

---

## 11. Open Questions

1. **Real-time or batch?** Real-time transfers (instant) vs batch window processing (T+0, T+1). Recommend real-time for Phase 1, batch settlement for netting.
2. **Fee capping?** Should the network enforce a maximum fee? Regulators may require this.
3. **Liquidity requirement?** Must coops prefund a settlement account? Or can we do net settlement? Recommend net settlement daily with prefunded buffer.
4. **Regulatory classification?** Are inter-coop transfers a "payment service" requiring separate licensing? Needs legal review per jurisdiction.
5. **Dispute resolution?** What happens when a sender claims the transfer was unauthorized? Need a dispute process.

---

## 12. Dependencies on Core Banking

| Capability | Required By | Status |
|------------|-------------|--------|
| `reset_session` on login | Phase 3 (portal integration) | Not done |
| Authorization on all controllers | Phase 2 (admin interface) | Not done |
| Stable test suite | All phases | 329 failures |
| Production deployment | All phases | Not deployed to real coop |
| SSL/HTTPS | All phases (API calls between coops) | Not done |
