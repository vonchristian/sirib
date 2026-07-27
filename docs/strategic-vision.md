# Sirib Strategic Vision

> **Document:** CTO Vision · **Status:** Draft · **Author:** CTO
> **Horizon:** 2026–2030

---

## 1. The North Star

> Every Filipino cooperative, regardless of size or location, has access to modern financial infrastructure that connects them to each other and to the broader economy — without surrendering their autonomy or paying rent to traditional banks.

Sirib is not a banking app. Sirib is a **cooperative financial network**. The core banking system is the on-ramp. The network is the destination.

---

## 2. The Problem We Solve

### Today's Reality

- **2,000+ cooperatives in the Philippines** — most run on legacy systems, spreadsheets, or manual ledgers
- **No interoperability** — Cooperative A and Cooperative B cannot transact directly. A member of Coop A cannot send money to a member of Coop B without going through a bank, GCash, or remittance center
- **Technology gap** — Small coops cannot afford modern core banking systems. They're priced out of digital transformation
- **Regulatory burden** — Each coop independently bears the cost of compliance, KYC, AML, fraud detection, reporting
- **Member experience** — Cooperative members expect the same digital experience they get from GCash, Maya, or banks. Most coops cannot deliver this

### The Sirib Answer

| Problem | Sirib Solution |
|---------|---------------|
| No affordable core system | Open-source, single-VPS deployable core banking |
| No interoperability | Inter-cooperative transfer and settlement network |
| High compliance costs | Shared KYC, shared fraud detection, shared AML |
| Poor member experience | Member portal, mobile-ready, embedded finance |
| No path to digital | All-in-one platform — deploy and launch in days, not months |

---

## 3. The Strategic Roadmap

```
2026                     2027                     2028                     2029-2030
│                        │                        │                        │
├─ Core Banking          ├─ Intercoop Network     ├─ Open Platform         ├─ Financial SuperApp
│  ──────────────────    │  ──────────────────    │  ──────────────────    │  ──────────────────
│  • Secure & stable     │  • Member transfers    │  • REST APIs           │  • Loan marketplace
│  • Auth + perms        │  • Settlement          │  • Developer portal    │  • Insurance products
│  • Database integrity  │  • Cooperative dir     │  • Webhooks            │  • Investment pool
│  • Test suite green    │  • Shared KYC          │  • Embedded widgets    │  • Digital banking
│  • Production deploy   │  • Fraud detection     │  • Mobile SDK          │  • Neo-coop banking
│                        │  • Network messaging   │  • Partner ecosystem   │  • BNPL for members
│                        │                        │                        │
└──── 1 coop live ──────┘──── 10 coops ─────────┘──── 50+ coops ────────┘──── 500+ coops ────
```

**Key Milestones:**
- **2026 Q4:** First cooperative live on Sirib Core Banking
- **2027 Q2:** First inter-cooperative transfer sent
- **2027 Q4:** 10 cooperatives on the network; settlement system operational
- **2028 Q2:** Public API launch; first third-party developer
- **2028 Q4:** 50 cooperatives; embedded finance available
- **2029:** 100+ cooperatives; positive unit economics
- **2030:** 500+ cooperatives; recognized cooperative financial network

---

## 4. Phases in Detail

### Phase 0: Core Banking Foundation (2026 Q3–Q4)

**Theme:** "Get one coop live."

Make the existing core banking platform production-ready. Fix security, add authorization, stabilize tests, deploy to a pilot cooperative.

**Success signal:** A real cooperative uses Sirib for daily operations for 30 days without a critical incident.

**Investment:** 3–4 months engineering time.

### Phase 1: Inter-Cooperative Transfers (2027 Q1–Q2)

**Theme:** "Connect two coops."

Enable member-to-member transfers between two cooperatives. Build routing, idempotency, and the first inter-coop API contract.

**Success signal:** Member of Coop A sends PHP 500 to member of Coop B, confirmed in under 30 seconds.

**Investment:** 3 months engineering + 1 month regulatory.

### Phase 2: Settlement & Clearing (2027 Q2–Q3)

**Theme:** "Balance the books."

Net settlement between cooperatives. Prefunded buffers, daily settlement cycle, reconciliation, dispute resolution.

**Success signal:** 10 cooperatives on the network settle PHP 5M+ daily with zero discrepancies.

**Investment:** 3 months engineering + regulatory engagement.

### Phase 3: Network Services (2027 Q3–Q4)

**Theme:** "The network is the product."

Cooperative directory, shared KYC, network-wide fraud detection, secure inter-coop messaging. These services make the network sticky.

**Success signal:** A new cooperative joining the network gets instant access to directory, KYC verification, and fraud alerts.

**Investment:** 3 months engineering.

### Phase 4: Open Platform (2028)

**Theme:** "Let others build on it."

Public APIs, webhooks, developer portal, SDKs, embedded finance widgets. Third-party developers build on the Sirib network.

**Success signal:** 5 third-party applications in production, processing real member transactions.

**Investment:** 4 months engineering + ongoing.

### Phase 5: SuperApp & Ecosystem (2029–2030)

**Theme:** "Everything a cooperative member needs."

Loan marketplace (lending across cooperatives), insurance products, pooled investments, digital banking services, buy-now-pay-later. Sirib becomes the financial operating system for cooperative members.

**Success signal:** Members use Sirib daily for banking, payments, lending, insurance, and investments.

**Investment:** Ongoing.

---

## 5. Revenue Model

| Phase | Revenue Stream | Description |
|-------|---------------|-------------|
| 0 | Implementation fee | One-time fee per cooperative deployment |
| 1 | Transaction fee | PHP 5–25 per inter-coop transfer |
| 2 | Settlement fee | PHP 50/month per cooperative |
| 3 | Network subscription | PHP 2,000–20,000/month per cooperative (tiered by member count) |
| 4 | API usage fee | Per-API-call or monthly subscription tier |
| 4 | Revenue share | 10–20% of transaction volume from embedded finance partners |
| 5 | Marketplace commission | 1–3% on loan marketplace, insurance, investments |

---

## 6. Defensibility Moat

| Moat | Description | Timeline |
|------|-------------|----------|
| **Network effects** | Each new cooperative makes the network more valuable | Phase 1+ |
| **Switching costs** | Deep integration with cooperative operations, data, and workflows | Phase 0 |
| **Data network effects** | Fraud detection, risk scoring, credit assessment improve with more data | Phase 3+ |
| **Ecosystem lock-in** | Third-party developers build on Sirib APIs, creating mutual dependency | Phase 4+ |
| **Regulatory moat** | Licensed payment system operator; regulatory approval to operate network | Phase 2+ |
| **Brand & trust** | Sirib becomes the recognized standard for cooperative technology | Phase 3+ |

---

## 7. Competitive Landscape

| Competitor | Positioning | Sirib Advantage |
|------------|-------------|-----------------|
| **Traditional core banking (T24, Flexcube, etc.)** | Enterprise, expensive, multi-tenant | Open-source, affordable for small coops, coop-specific |
| **Philippine coop tech providers (CoopServ, CoopLink)** | Local, coop-focused, legacy tech | Modern stack (Rails 8 + Hotwire), inter-coop network, open APIs |
| **GCash / Maya / PayMaya** | Consumer fintech, mass market | Cooperative-focused, member-owned, lower fees, network governance |
| **Banks (RCBC, BPI, Landbank)** | Universal banking | Coop-to-coop focus, member-centric, non-profit ethos |
| **Blockchain-based coops (CoopDAO etc.)** | Decentralized, experimental | Practical, regulatory-compliant, production-ready |

---

## 8. Key Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| First coop deployment fails | Medium | High | Extended beta; dedicated coop partner; engineering onsite |
| Regulatory roadblocks | High | Very High | Engage BSP early; legal counsel; payment system operator registration |
| Cannot recruit coop customers | Medium | High | Focus on 1-3 pilot coops; hands-on onboarding; prove value before scaling |
| Security incident | Low | Critical | Security audit before each phase; bug bounty; insurance |
| Engineering team too small | High | High | OSS community; contract developers; focus on most impactful work |
| Competition from big tech | Medium | Medium | Network effects + first-mover in coop-specific space; regulator relationships |
| Coop governance complexity | High | Medium | Standardized network agreement; clear governance model; dispute resolution |

---

## 9. Investment Requirements

| Period | Engineering | Infrastructure | Regulatory | Marketing | Total (PHP) |
|--------|------------|---------------|------------|-----------|-------------|
| 2026 H2 | 3 FTEs | ₱50K/month | ₱500K | Minimal | ~₱3M |
| 2027 | 5 FTEs | ₱100K/month | ₱1M | ₱500K | ~₱7M |
| 2028 | 8 FTEs | ₱200K/month | ₱500K | ₱2M | ~₱12M |
| 2029–30 | 10–15 FTEs | ₱500K/month | ₱500K | ₱5M | ~₱20M/year |

---

## 10. Why We Win

1. **We think like cooperatives, not like banks.** Our product, pricing, and governance are designed for cooperatives' unique structure. We are not a bank trying to sell to coops. We are a coop building for coops.

2. **Network effects are existential for coops.** A single coop on Sirib gets a modern core banking system. Ten coops on Sirib get a payment network. Fifty coops on Sirib get a financial ecosystem that competes with banks. The value compounds.

3. **Open source aligns with cooperative values.** Cooperatives are democratic, member-owned organizations. Open-source software shares those values. Sirib's code is owned by the community, not a vendor.

4. **Regulatory tailwind.** The Philippine government (BSP, CDA) actively promotes cooperative digitalization. Sirib aligns with national financial inclusion goals.

5. **Timing.** Philippine cooperatives are under pressure to digitize. Their members expect digital services. The window is open now.

---

## 11. Immediate Next Steps

1. **Ship the core banking foundation** — security, authorization, tests, deploy to one coop
2. **Find the pilot cooperative** — identify a tech-forward, medium-sized coop willing to co-build
3. **Register the entity** — decide: Sirib as a software company, a payment system operator, or a cooperative itself?
4. **Build the team** — hire 2 more engineers (Rails + DevOps)
5. **Engage BSP early** — regulatory pre-consultation to understand licensing requirements

---

## 12. Closing

> The Philippines has 13,000+ cooperatives serving 12+ million members. Most operate on legacy systems. None can transact with each other.
>
> Sirib changes that. One cooperative, one transfer, one API at a time.
>
> The core banking system is the foot in the door. The network is the monument.

---

**End of Strategic Vision.**
