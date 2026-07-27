# PRD: Open API Ecosystem & Embedded Finance

> **Status:** Draft · **Owner:** CTO · **Version:** 1.0
> **Dependency:** Cooperative Network Services (Phase 3)
> **Target:** Phase 4 — Platform expansion

---

## 1. Executive Summary

The final layer of the Sirib platform: opening the cooperative banking network to third-party developers, fintech partners, and embedded finance use cases. This transforms Sirib from a banking application into a banking platform.

Third-party developers can build on top of Sirib's APIs — mobile wallets, payment gateways, accounting software integrations, lending marketplaces, and more. Cooperatives become platforms themselves, offering financial services through partner channels.

---

## 2. Why This Matters

- **Platform economics.** The most valuable financial companies are platforms (Stripe, Plaid, Adyen), not banks. Sirib's moat is the network; APIs make the network programmable.
- **Ecosystem over features.** Sirib cannot build every feature every cooperative needs. APIs let the ecosystem fill the gaps.
- **Embedded finance.** Cooperatives' members already use GCash, Maya, Shopee, Lazada. Sirib APIs let cooperatives meet members where they are.
- **Revenue diversification.** API usage fees, revenue sharing with third-party developers, marketplace commissions.
- **Defensibility.** The more third-party integrations depend on Sirib APIs, the harder it is to displace the network.

---

## 3. API Product Lines

### 3.1 Core Banking API

Expose core banking operations via RESTful APIs:

| API | Description | Scope |
|-----|-------------|-------|
| `GET /api/v1/members` | Member lookup and verification | Member data |
| `GET /api/v1/accounts` | Account balance and transaction history | Account data |
| `POST /api/v1/transfers` | Initiate transfer (internal or inter-coop) | Transactions |
| `GET /api/v1/transactions` | Transaction history with filters | Transactions |
| `POST /api/v1/loans/apply` | Submit loan application | Lending |
| `GET /api/v1/loans/:id` | Loan status and repayment schedule | Lending |
| `POST /api/v1/loans/:id/pay` | Make loan payment | Lending |
| `POST /api/v1/savings/deposit` | Deposit to savings account | Savings |
| `POST /api/v1/savings/withdraw` | Withdraw from savings account | Savings |
| `GET /api/v1/statements` | Account statement generation | Reporting |

### 3.2 Network API

Expose network-level capabilities:

| API | Description | Scope |
|-----|-------------|-------|
| `GET /api/v1/network/cooperatives` | Cooperative directory search | Network |
| `POST /api/v1/network/transfer` | Inter-cooperative transfer initiation | Network |
| `GET /api/v1/network/transfer/:id` | Cross-coop transfer status | Network |
| `POST /api/v1/network/kyc/verify` | KYC verification query | Network (KYC) |
| `POST /api/v1/network/fraud/check` | Fraud indicator check | Network (Fraud) |

### 3.3 Webhooks

Event-driven notifications for real-time integration:

| Webhook | Trigger | Payload |
|---------|---------|---------|
| `transfer.completed` | Transfer credited to recipient | Transfer details, amount, fee |
| `transfer.failed` | Transfer could not be completed | Error reason, auto-reversal |
| `account.credited` | Account received funds | Amount, source, new balance |
| `account.debited` | Account sent funds | Amount, destination, new balance |
| `loan.disbursed` | Loan funds released | Loan ID, amount, member |
| `loan.payment_received` | Loan payment processed | Payment ID, amount, remaining |
| `member.kyc_updated` | Member KYC status changed | Member ID, new level |
| `fraud.alert` | Suspicious activity detected | Alert type, severity, details |

### 3.4 Embedded Finance Widgets

Pre-built, embeddable UI components for partner websites/apps:

| Widget | Description |
|--------|-------------|
| **Checkout Button** | "Pay with Cooperative Savings" — embedded payment for e-commerce |
| **Balance Widget** | Show cooperative account balance on partner dashboard |
| **Transaction History** | Embeddable transaction list with search |
| **Loan Application Form** | Embedded loan application for partner websites |
| **Member Verification** | Identity verification for partner onboarding |
| **Transfer Widget** | Send money to any cooperative member |

---

## 4. Developer Experience

### 4.1 Developer Portal

```
Developers.Sirib.ph
├── Documentation
│   ├── Getting Started Guide
│   ├── API Reference (OpenAPI 3.0)
│   ├── Webhook Guide
│   ├── SDK Documentation
│   └── Migration Guides
├── API Keys
│   ├── Create/Revoke Keys
│   ├── Permission Scopes
│   └── Usage Statistics
├── Playground
│   ├── Interactive API Console
│   └── Webhook Tester
├── Status
│   ├── API Uptime
│   ├── Incident History
│   └── Scheduled Maintenance
└── Support
    ├── Community Forum
    ├── Ticket System
    └── Slack/Discord
```

### 4.2 SDKs & Libraries

| SDK | Language | Coverage |
|-----|----------|----------|
| `sirib-ruby` | Ruby | Full API + webhook verification |
| `sirib-python` | Python | Full API |
| `sirib-js` | JavaScript/TypeScript | Full API + web widget integration |
| `sirib-php` | PHP | Core payments API |
| `sirib-mobile` | React Native | Mobile SDK for embedded banking |
| `sirib-flutter` | Flutter | Mobile SDK |

### 4.3 Authentication & Authorization

```http
# API Key (server-to-server)
Authorization: Bearer sirib_live_abc123def456

# OAuth 2.0 (user-authorized)
POST /oauth/token
grant_type=authorization_code
code=abc123
client_id=sirib_cli_xyz
client_secret=sirib_sec_789

# Response
{
  "access_token": "sirib_oat_xxx",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "transfers:read accounts:read"
}
```

| Feature | API Key | OAuth 2.0 |
|---------|---------|------------|
| Use case | Server-to-server, admin apps | User-authorized, third-party apps |
| Granularity | Fixed per-key scopes | Per-user, per-session scopes |
| Rotation | Manual or scheduled | Automatic (refresh tokens) |
| Audit | Tracked by key ID | Tracked by user + app |
| Recommended for | Cooperative IT, internal tools | Fintech partners, member-facing apps |

---

## 5. Technical Architecture

### 5.1 API Gateway

```
[Partner App] → [Cloudflare/CDN] → [API Gateway (Rails/Grape)]
                                         ↓
                              [Rate Limiter (Rack::Attack)]
                                         ↓
                              [Authentication (API Key / OAuth)]
                                         ↓
                              [Permission Scoping]
                                         ↓
                              [Rate Limit Check]
                                         ↓
                              [Controller / Service]
                                         ↓
                              [Sirib Network / Core Banking]
```

### 5.2 Rate Limiting

| Tier | Rate Limit | Price |
|------|-----------|-------|
| Sandbox | 100 req/min | Free |
| Starter | 1,000 req/min | PHP 5,000/month |
| Business | 10,000 req/min | PHP 20,000/month |
| Enterprise | Custom | Custom |

### 5.3 Webhook Delivery

```
Sirib → Webhook → Partner's Endpoint
  ↓ on failure (retry)
Sirib → Webhook → Partner's Endpoint
  ↓ (exponential backoff: 1s, 5s, 30s, 5min, 30min, 2hr, 6hr)
Sirib → Webhook → Partner's Endpoint
  ↓ (max 7 retries)
Sirib: Mark as "failed" → alert partner
```

### 5.4 Data Model Additions

```ruby
# API keys for third-party developers
create_table "api_keys" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.string :name, null: false
  t.string :key_digest, null: false  # bcrypt hash of the actual key
  t.string :key_prefix, null: false  # first 8 chars for identification (e.g., "sirib_live_abc")
  t.string :scopes, array: true, default: []
  t.string :status, default: "active"  # active | revoked | expired
  t.datetime :last_used_at
  t.datetime :expires_at
  t.timestamps
end
add_index :api_keys, :key_digest, unique: true

# OAuth applications
create_table "oauth_applications" do |t|
  t.string :name, null: false
  t.string :redirect_uri, null: false
  t.string :scopes, array: true, default: []
  t.boolean :confidential, default: true
  t.timestamps
end

# Webhook endpoints
create_table "webhook_endpoints" do |t|
  t.references :cooperative, null: false, foreign_key: true
  t.string :url, null: false
  t.string :secret, null: false  # HMAC signing secret
  t.string :events, array: true, default: []  # subscribed event types
  t.string :status, default: "active"  # active | disabled | failed
  t.timestamps
end

# Webhook delivery log
create_table "webhook_deliveries" do |t|
  t.references :webhook_endpoint, null: false
  t.string :event_type, null: false
  t.jsonb :payload
  t.integer :http_status
  t.boolean :success, default: false
  t.integer :attempts, default: 1
  t.text :error_message
  t.timestamps
end
add_index :webhook_deliveries, [:webhook_endpoint_id, :created_at], name: "idx_webhook_deliveries_recent"
```

---

## 6. Partner Onboarding Flow

```
1. Developer registers at developers.sirib.ph
2. Selects tier (Sandbox / Starter / Business / Enterprise)
3. Cooperative approves the partner app (cooperative admin)
4. API key generated (sandbox or live)
5. Developer builds integration using docs + SDK
6. Sandbox testing (isolated test environment)
7. Submit for review (Sirib reviews integration quality + security)
8. Approved → API key promoted to live
9. Production usage begins
10. Ongoing: usage monitoring, billing, support
```

---

## 7. Compliance & Risk

| Concern | Mitigation |
|---------|-----------|
| API abuse | Rate limiting, per-key throttling, anomaly detection |
| Data leakage | OAuth scopes control data access; no PII in webhook payloads by default |
| Unauthorized access | API key rotation, OAuth with PKCE, audit logging |
| Partner security review | Automated security scan + manual review before live promotion |
| Data privacy | Partners must have privacy policy; data processing agreement required |
| Regulatory compliance | APIs comply with BSP digital banking framework; partner obligations in contract |

---

## 8. Implementation Phases

### Phase 1: API Foundation (4 weeks)

- API key management (generate, scopes, revoke, rotate)
- Core Banking API (members, accounts, transfers, transactions)
- Rate limiting (Rack::Attack configuration)
- API documentation site (OpenAPI 3.0 spec)
- Ruby SDK (`sirib-ruby`)

### Phase 2: Webhooks (2 weeks)

- Webhook endpoint management
- Event subscription system
- Webhook delivery engine (retry with backoff)
- Webhook signing (HMAC-SHA256)
- Delivery dashboard and logs

### Phase 3: OAuth & Developer Portal (3 weeks)

- OAuth 2.0 authorization server
- Developer portal UI
- API key and OAuth management dashboard for coops
- Interactive API playground
- Usage analytics and billing

### Phase 4: Embedded Finance (4 weeks)

- Checkout widget (embeddable payment button)
- Balance and transaction widgets
- Loan application embed
- Mobile SDK (Flutter + React Native)
- Third-party app review and approval workflow

### Phase 5: Marketplace (ongoing)

- Partner directory (approved third-party apps)
- Revenue sharing model and payments
- Partner support system
- Community forum
- Partner success program

---

## 9. Success Criteria

- [ ] 5+ third-party developers building on the platform within 6 months of API launch
- [ ] API uptime: 99.95% monthly
- [ ] Median API response time: < 200ms (P95)
- [ ] Webhook delivery success rate: > 99.5% within 3 retries
- [ ] Partner onboarding: application to production in < 7 days
- [ ] 3+ embedded finance integrations live (e-commerce checkout, wallet, lending)
- [ ] API revenue covers platform operating costs
- [ ] Security audit passes with no critical findings

---

## 10. Open Questions

1. **API versioning strategy?** URL-based (`/v1/`, `/v2/`) or header-based? Recommend URL-based for simplicity.
2. **Rate limit enforcement?** Hard limits (block) or soft (throttle + warn)? Recommend soft with clear headers.
3. **Webhook retry policy?** How many retries? How long before webhook endpoint is auto-disabled?
4. **Partner review process?** Automated + manual? What are the security minimums?
5. **Pricing model?** Per-API-call? Monthly subscription? Revenue share on transactions?
6. **Sandbox environment?** Separate instance with synthetic data? How to seed realistically?
7. **Open source SDKs?** MIT-licensed on GitHub? Yes — encourages adoption.
