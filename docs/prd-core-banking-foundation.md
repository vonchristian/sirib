# PRD: Core Banking Foundation

> **Status:** Draft · **Owner:** CTO · **Version:** 1.0
> **Dependency:** None (Phase 0)
> **Target:** MVP for individual cooperative banking operations

---

## 1. Executive Summary

The Core Banking Foundation is the prerequisite for everything else. Before Sirib can interconnect cooperatives, each cooperative must be able to run its banking operations reliably, securely, and independently on the platform.

This PRD covers the stabilization, hardening, and completion of the existing Sirib core banking platform so it can be deployed to production for a single cooperative.

---

## 2. Why This Matters

- **No interconnection without individual stability.** An unstable core means an unstable network.
- **Trust is earned at the coop level first.** A coop will not connect its members to a network it doesn't trust for its own operations.
- **The audit hurdle.** Every regulator will audit the core before they audit the network.
- **Deployment is the proving ground.** Getting one coop live proves the model, reveals real-world bugs, and builds the operational playbook.

---

## 3. Scope

### In Scope

- All Critical and High security fixes (session fixation, SSL, cookie flags, webhook auth)
- Authorization on all management and financial controllers
- Branch-level data isolation
- Database integrity (missing FKs, indexes, type mismatches)
- Test stabilization (329 failures → green)
- Core controller request specs (treasury, portal, loans, equity)
- Production deployment automation and monitoring
- Documentation for coop administrators

### Out of Scope

- Inter-cooperative features (separate PRDs)
- Mobile apps
- Real-time messaging / chat
- Advanced BI/analytics
- Full event sourcing

---

## 4. Functional Requirements

### 4.1 Security Hardening

| ID | Requirement | Priority |
|----|-------------|----------|
| SEC-01 | Login/logout calls `reset_session` to prevent session fixation | P0 |
| SEC-02 | Production enforces HTTPS via `assume_ssl` | P0 |
| SEC-03 | Admin session cookie has `secure` flag in production | P0 |
| SEC-04 | Webhook endpoint authenticates via HMAC signature | P0 |
| SEC-05 | Login uses a single generic error message for all failure paths | P1 |
| SEC-06 | MFA session stores signed timestamp alongside user ID | P1 |
| SEC-07 | After-login redirect validates destination against whitelist | P1 |
| SEC-08 | Portal login enforces account lockout (matching admin) | P1 |
| SEC-09 | Password reset token is not exposed in redirect URL | P1 |
| SEC-10 | Enrollment lockout uses database, not session cookie | P2 |
| SEC-11 | File uploads validate content type and size | P2 |
| SEC-12 | Money values use `BigDecimal` not `to_f` across all controllers | P2 |

### 4.2 Authorization

| ID | Requirement | Priority |
|----|-------------|----------|
| AUTH-01 | All 25 management controllers enforce `require_permission!` | P0 |
| AUTH-02 | All 15 financial controllers enforce permission checks | P0 |
| AUTH-03 | All financial queries scope by `Current.branch` | P0 |
| AUTH-04 | Ad-hoc role checks (`treasurer?`) replaced with `require_permission!` | P1 |
| AUTH-05 | Cross-branch access attempts return 403 | P1 |

### 4.3 Core Banking Features

| ID | Requirement | Priority |
|----|-------------|----------|
| CB-01 | Cooperative can create branches, users, roles, and permissions | P0 |
| CB-02 | Teller can open cash sessions, accept deposits, process withdrawals | P0 |
| CB-03 | Member onboarding with enrollment flow and MFA | P0 |
| CB-04 | Savings account creation, deposit, withdrawal | P0 |
| CB-05 | Loan application, approval, disbursement, repayment | P0 |
| CB-06 | Share capital purchase and management | P0 |
| CB-07 | Chart of accounts and journal entry posting | P0 |
| CB-08 | Financial reports (balance sheet, income statement, trial balance) | P0 |
| CB-09 | Member portal for self-service balance inquiry and transaction history | P1 |
| CB-10 | Audit log for all financial transactions | P0 |

### 4.4 Database Integrity

| ID | Requirement | Priority |
|----|-------------|----------|
| DB-01 | All foreign key columns have database-level constraints | P0 |
| DB-02 | All polymorphic associations have composite indexes | P1 |
| DB-03 | Polymorphic ID columns use `bigint`, not `integer` | P2 |
| DB-04 | `accounts.created_by_id`/`modified_by_id` type fixed (uuid→bigint) | P1 |
| DB-05 | All model associations have correct `dependent` options | P1 |
| DB-06 | All callbacks that create records are converted to service objects | P2 |
| DB-07 | `acts_as_nested_set` properly configured on `Branch` or orphan columns removed | P1 |
| DB-08 | All N+1 query patterns are resolved | P2 |

---

## 5. Technical Architecture

### 5.1 Deployment Architecture

```
[Cloudflare/CDN] → [Kamal Proxy] → [Rails App (Puma, 5 threads)]
                                       ↓
                              [PostgreSQL (accessory)]
                                       ↓
                              [Solid Queue (async jobs)]
```

- **Single tenant per instance** — each cooperative deploys independently
- **Deployment via Kamal** — Docker containers on single VPS (2GB minimum)
- **Database as Kamal accessory** — PostgreSQL with tuned config
- **No SSL termination in app** — Kamal proxy handles it

### 5.2 Authentication Flow

```
Login → rate_limit check → AccountLockoutService → password verify
  → reset_session → MFA challenge (if enabled) → start_new_session
  → redirect (validated against whitelist)
```

### 5.3 Authorization Flow

```
Request → require_authentication (session valid?)
  → require_permission! (user has role with permission?)
  → scope_by_branch (data filtered to user's branch?)
  → action
```

---

## 6. Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-01 | 99.9% uptime during banking hours | Measured weekly |
| NFR-02 | Login response time < 500ms | P95 |
| NFR-03 | Transaction posting < 1s | P95 |
| NFR-04 | Report generation < 5s | P95 for monthly |
| NFR-05 | Concurrent users: 50 per branch, 5 branches | Per instance |
| NFR-06 | Test pass rate: 100% (0 failures, 0 pending) | CI gate |
| NFR-07 | Brakeman score: 0 warnings | CI gate |

---

## 7. Dependencies

- No external dependencies — runs entirely on the single VPS
- Kamal for deployment (already configured)
- PostgreSQL 16 (via Kamal accessory)
- Ruby 4.0 + Rails 8.0 (current stack)

---

## 8. Implementation Phases

### Phase A: Security Hardening (1 week)

Files: `sessions_controller.rb`, `mfa_controller.rb`, `portal/sessions_controller.rb`, `authentication.rb`, `portal_authentication.rb`, `production.rb`, `webhooks_controller.rb`, `passwords_controller.rb`, `enrollment_controller.rb`

### Phase B: Authorization (1 week)

Files: All 25 management controllers, all 15 financial controllers, new `FinancialBaseController`, branch scoping on queries

### Phase C: Database Integrity (1 week)

Files: ~10 migrations, model files (validations, associations, `dependent`), `append_only_override.rb`

### Phase D: Test Stabilization (2 weeks)

Files: 329 failing specs across 6 clusters, new spec files for uncovered controllers/models

### Phase E: Production Readiness (1 week)

Files: SSL config, monitoring, backup scripts, admin documentation

---

## 9. Success Criteria

- [ ] All Critical and High security issues resolved
- [ ] All controllers enforce proper authorization
- [ ] All database FKs and indexes in place
- [ ] Test suite: 100% passing, 0 pending
- [ ] Request specs exist for all management, treasury, portal, loans, and equity controllers
- [ ] Model specs exist for all models
- [ ] Production deployment: login, deposits, withdrawals, loans all verified working
- [ ] Brakeman: 0 warnings
- [ ] Deployed to a single cooperative for beta testing

---

## 10. Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Session fix still broken after fix | Low | Critical | Automated request spec verifies `reset_session` called |
| SSL breaks existing login flow | Medium | High | Test end-to-end with kamal-proxy before production deploy |
| Test stabilization uncovers new bugs | High | Medium | Fix bugs as found; regressions are test failures |
| Cooperative onboarding reveals missing features | Medium | High | Beta period with dedicated coop partner for feedback |
| Database migrations cause downtime | Low | High | Use `CONCURRENTLY` for indexes, deploy during maintenance window |
