# PRD: Cooperative Network Services

> **Status:** Draft · **Owner:** CTO · **Version:** 1.0
> **Dependency:** Inter-Cooperative Settlement (Phase 2)
> **Target:** Phase 3 — Shared network infrastructure

---

## 1. Executive Summary

Once cooperatives can transfer money between each other (Phase 1) and settle their net positions (Phase 2), the network needs a shared services layer to scale. This includes a cooperative directory for discovery, shared KYC/AML services to reduce compliance costs, network-wide fraud detection, and a cooperative messaging system for network communication.

This PRD defines the platform services that run on the Sirib network node and provide value to all connected cooperatives.

---

## 2. Why This Matters

- **Network effects multiply with shared services.** Each additional cooperative makes the network more valuable for everyone.
- **Cost sharing.** Small cooperatives cannot afford individual KYC/AML systems, fraud detection, or dedicated compliance officers. Shared services lower the barrier to entry.
- **Consistent standards.** The network enforces minimum compliance, security, and operational standards across all participants.
- **Data network effects.** More data means better fraud detection, better risk scoring, and better products for everyone.

---

## 3. Service Catalog

### 3.1 Cooperative Directory

**Purpose:** Allow cooperatives to discover and verify each other on the network.

```
Directory Entry:
┌─────────────────────────────────────┐
│  Cooperative Name: Magkakapit-Kapit │
│  Registration: CDA-R-2024-00123     │
│  Region: Central Luzon              │
│  Members: 12,450                    │
│  Asset Size: PHP 250M               │
│  Services Offered: Savings, Loans,  │
│    Insurance, Remittances           │
│  Contacts: admin@magkakapit-kapit   │
│  Status: Active, Verified           │
│  Network Since: 2025-03-15          │
└─────────────────────────────────────┘
```

| ID | Requirement | Priority |
|----|-------------|----------|
| DIR-01 | Each cooperative has a verified directory profile | P0 |
| DIR-02 | Profile includes name, registration number, region, member count, services | P0 |
| DIR-03 | Directory is searchable by name, region, and services offered | P0 |
| DIR-04 | Cooperatives can update their own profile (subject to network verification) | P1 |
| DIR-05 | Directory shows network health status (online/offline, recent activity) | P2 |
| DIR-06 | Directory feeds into the transfer routing table automatically | P0 |

### 3.2 Shared KYC/AML

**Purpose:** Reduce duplicate KYC efforts when members interact across cooperatives.

```
Scenario:
1. Maria is a member of Coop A (KYC completed 2024)
2. Maria wants to receive a transfer from Coop B
3. Coop B needs to verify Maria's identity (regulatory requirement)
4. Instead of Maria submitting documents again, Coop B queries the network
5. Network returns: "Maria Dela Cruz, verified by Coop A on 2024-03-15, KYC Level 2"
6. Coop B can accept this (if they trust Coop A's KYC) or request additional info
```

| ID | Requirement | Priority |
|----|-------------|----------|
| KYC-01 | Member KYC status is shareable across the network (with member consent) | P0 |
| KYC-02 | KYC data shared: identity verification status, level, verification date — NOT scanned documents | P1 |
| KYC-03 | Receiving cooperative can request additional KYC if their standards are higher | P1 |
| KYC-04 | KYC consent is revocable by the member at any time | P0 |
| KYC-05 | Network maintains a KYC standards registry (what each coop requires) | P2 |
| KYC-06 | AML screening: network flags members on watchlists across all coops | P1 |
| KYC-07 | Suspicious activity reports (SARs) can be shared between compliance officers | P2 |

### 3.3 Network Fraud Detection

**Purpose:** Detect fraud patterns that span multiple cooperatives.

```
Examples of Cross-Coop Fraud:
- Same phone number used to open accounts in 3 cooperatives → benefit fraud
- Rapid transfers through 5 cooperatives in 1 hour → money laundering
- Known fraudster from Coop A attempts to register in Coop B → blocked
```

| ID | Requirement | Priority |
|----|-------------|----------|
| FRAUD-01 | Network maintains a shared fraud indicator database (phones, IDs, devices) | P0 |
| FRAUD-02 | Cooperatives can submit fraud indicators (with evidence) to the network | P0 |
| FRAUD-03 | Network detects anomalous transfer patterns (velocity, amount, geography) | P1 |
| FRAUD-04 | Suspicious transfers can be auto-held pending manual review | P1 |
| FRAUD-05 | Fraud alerts are sent to both affected cooperatives | P0 |
| FRAUD-06 | Cooperatives can query: "Is this member ID known to be associated with fraud?" | P1 |

### 3.4 Network Messaging

**Purpose:** Secure communication channel between cooperatives.

| ID | Requirement | Priority |
|----|-------------|----------|
| MSG-01 | Cooperatives can send secure messages to each other via the network | P1 |
| MSG-02 | Messages support: text, file attachments, structured data (JSON) | P1 |
| MSG-03 | Message delivery is guaranteed (retry + ack) | P1 |
| MSG-04 | Messages are encrypted at rest and in transit | P0 |
| MSG-05 | Message types: settlement queries, dispute filing, compliance inquiries, general admin | P1 |
| MSG-06 | Message audit log: all communication between coops is recorded for compliance | P1 |

---

## 4. Technical Architecture

### 4.1 Network Node Services

```
┌──────────────────────────────────────────────────────────┐
│                Sirib Network Node                          │
│                                                            │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────┐    │
│  │  Directory   │ │   KYC/AML   │ │  Fraud Detection  │    │
│  │   Service    │ │   Service   │ │    Service        │    │
│  └──────┬───────┘ └──────┬──────┘ └────────┬─────────┘    │
│         │                │                  │              │
│  ┌──────┴───────┐ ┌──────┴──────┐ ┌────────┴─────────┐    │
│  │   Messaging  │ │  Reporting  │ │  Administration  │    │
│  │   Service    │ │   Service   │ │    Service       │    │
│  └──────────────┘ └─────────────┘ └──────────────────┘    │
│                                                            │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Network Database (PostgreSQL)             │    │
│  │  - Cooperative profiles   - KYC attestations       │    │
│  │  - Fraud indicators       - Message store          │    │
│  │  - Audit log              - Network configuration  │    │
│  └────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### 4.2 Data Flow: KYC Query

```
Coop B → Network Node:
  GET /network/kyc/verify
  { member_phone: "09171234567", consent_token: "abc123" }

Network Node → Coop A:
  Forwarded KYC query with member consent

Coop A → Network Node:
  { verified: true, level: "L2", verified_at: "2024-03-15" }

Network Node → Coop B:
  { verified: true, level: "L2", verified_by: "Coop A",
    verified_at: "2024-03-15", expires_at: "2025-03-15" }

Network Node → Audit Log:
  { event: "kyc_query", coop_b: "Coop B", coop_a: "Coop A",
    member_id_hashed: "sha256(…)", timestamp: "…" }
```

### 4.3 Data Flow: Fraud Indicator Submission

```
Coop A → Network Node:
  POST /network/fraud/indicators
  { type: "phone", value: "09171234567",
    reason: "Confirmed fraud - fake loan applications",
    evidence_hash: "sha256(…)", confidence: 0.95 }

Network Node:
  1. Validates: received from authorized cooperative
  2. Checks: does this indicator already exist?
  3. Updates: increment confidence score, add source
  4. Broadcasts: notify all cooperatives (async)
  5. Logs: audit trail

Coop B (subscribing):
  Receives alert → blocks member registration with this phone
```

---

## 5. Data Model Additions

```ruby
# Cooperative directory
create_table "network_cooperative_profiles" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.string :registration_number
  t.string :region
  t.integer :member_count
  t.decimal :asset_size, precision: 18, scale: 2
  t.string :services, array: true, default: []  # savings, loans, insurance, remittance
  t.string :status, default: "pending"  # pending | active | suspended | deactivated
  t.string :verification_status, default: "unverified"  # unverified | verified | flagged
  t.timestamps
end

# KYC attestations
create_table "network_kyc_attestations" do |t|
  t.references :member, null: false
  t.references :attesting_cooperative, null: false  # the coop that performed KYC
  t.string :kyc_level, null: false  # L1, L2, L3
  t.string :identity_status  # verified | pending | rejected
  t.datetime :verified_at
  t.datetime :expires_at
  t.boolean :consent_granted, default: false
  t.datetime :consent_revoked_at
  t.timestamps
end
add_index :network_kyc_attestations, [:member_id, :attesting_cooperative_id], unique: true, name: "idx_kyc_unique"

# Fraud indicators (shared database)
create_table "network_fraud_indicators" do |t|
  t.string :indicator_type, null: false  # phone, email, device_id, id_number, ip_address
  t.string :value, null: false           # the actual phone, email, etc.
  t.decimal :confidence_score, precision: 5, scale: 4, default: 0.0
  t.integer :report_count, default: 1
  t.string :status, default: "active"    # active | reviewed | dismissed
  t.text :notes
  t.timestamps
end
add_index :network_fraud_indicators, [:indicator_type, :value], unique: true, name: "idx_fraud_indicator_unique"

# Fraud indicator sources
create_table "network_fraud_indicator_sources" do |t|
  t.references :fraud_indicator, null: false
  t.references :reporting_cooperative, null: false
  t.text :reason
  t.string :evidence_hash
  t.timestamps
end

# Network messages
create_table "network_messages" do |t|
  t.references :sender_cooperative, null: false
  t.references :recipient_cooperative, null: false
  t.string :message_type, null: false  # general, dispute, compliance, settlement
  t.string :subject
  t.text :body
  t.jsonb :attachments, default: []
  t.string :status, default: "pending"  # pending | delivered | read | archived
  t.datetime :delivered_at
  t.datetime :read_at
  t.timestamps
end
add_index :network_messages, [:sender_cooperative_id, :recipient_cooperative_id, :created_at], name: "idx_messages_conversation"
```

---

## 6. Governance Model

| Element | Description |
|---------|-------------|
| **Network Operator** | Sirib (or a separate entity) operates the network node |
| **Membership** | Cooperatives apply to join; verified by Sirib |
| **Rules** | Network participation agreement (terms of service) |
| **Fees** | Monthly subscription + per-transaction fees |
| **Disputes** | Network admin mediates; appeals process |
| **Suspension** | Network operator can suspend cooperative for violations |
| **Exit** | Cooperative can leave with 30 days notice; settlement of outstanding obligations |

---

## 7. Security & Privacy

| Concern | Mitigation |
|---------|-----------|
| KYC data privacy | Only verification status shared, not documents. Member consent required. GDPR/PDPA compliant. |
| Fraud database privacy | Indicators are hashed for search, not stored in plaintext (except phones, which are PII — needs legal review) |
| Message confidentiality | End-to-end encryption between cooperatives |
| Network node compromise | Node holds routing data, not member financial data. Funds protected by per-coop private keys. |
| Cooperative impersonation | Mutual TLS between coops and network node. |

---

## 8. Implementation Phases

### Phase 1: Cooperative Directory (2 weeks)

- Directory profile model and CRUD
- Verification workflow (admin approves coop profiles)
- Search by name, region, services
- Directory API for transfer routing integration

### Phase 2: Network Messaging (2 weeks)

- Secure message model and delivery
- Message inbox UI in management dashboard
- Message types: general, dispute, settlement
- Delivery guarantees (retry + ack)

### Phase 3: Shared KYC (3 weeks)

- KYC attestation model
- Member consent flow
- KYC query API (request → consent → respond)
- KYC standards registry
- KYC integration with member onboarding

### Phase 4: Fraud Detection (3 weeks)

- Fraud indicator model and submission API
- Duplicate detection and confidence scoring
- Cross-coop fraud pattern detection
- Alert system for suspicious activities
- Dashboard for fraud analysts

---

## 9. Success Criteria

- [ ] 10+ cooperatives registered in directory with verified profiles
- [ ] Coop-to-coop secure messaging works end-to-end
- [ ] KYC query between coops completes in < 5 seconds with consent
- [ ] Fraud indicator submitted by one coop is available to all others within 60 seconds
- [ ] Cross-coop fraud pattern detection identifies simulated attack scenarios
- [ ] All shared services have documented APIs
- [ ] Privacy impact assessment completed

---

## 10. Open Questions

1. **Entity structure?** Should the network be run by Sirib or a separate entity? (Regulatory reasons may require separation.)
2. **KYC liability?** If Coop A's KYC is wrong and Coop B relies on it, who is liable?
3. **Fraud database governance?** Who decides what goes into the fraud database? Appeal process?
4. **Minimum standards?** What are the minimum KYC, security, and operational standards to join?
5. **Pricing model?** Flat monthly fee? Per-transaction? Tiered by member count?
