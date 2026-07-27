# Testing Audit & Roadmap

> Audit date: July 2026

---

## Current State

| Metric | Value |
|--------|-------|
| Total RSpec examples | 1,351 |
| Passed | 1,012 (74.9%) |
| **Failed** | **329 (24.4%)** |
| Pending | 10 (0.7%) |
| RSpec spec files | 158 |
| Playwright E2E specs | 66 |
| Factory files | 53 |

---

## Failure Clusters

### Cluster 1: Running Balance Computation (~100+ failures)

**Affected files:** `spec/requests/accounting/accounts_spec.rb` (15), plus many accounting model and service specs

**Known issue** (documented in AGENTS.md): Running balance computation has pre-existing failures unrelated to new development.

**Fix:** Debug `RunningBalance` model computation logic and ensure entries post with correct running balances.

### Cluster 2: External Module (~50 failures)

**Affected files:**
- `spec/models/external/bank_transaction_spec.rb` (12)
- `spec/requests/external/accounts_spec.rb` (10)
- `spec/requests/external/reconciliation_spec.rb` (10)
- Plus bank and document specs

**Likely cause:** External HTTP calls not stubbed (no `webmock`/`vcr` gem). Factory data may not match expected external API responses.

**Fix:** Add `webmock` + `vcr` gems. Update factories and stubs for external API interactions.

### Cluster 3: Messaging Module (~42 failures)

**Affected files:**
- `spec/services/messaging/*` (~24)
- `spec/models/messaging/*` (~18)
- `spec/requests/management/messaging/providers_spec.rb` (11)

**Likely cause:** Provider stubs broken or incomplete. Channel/Messsage model factories out of date.

### Cluster 4: Identity Enrollment (10 failures)

**File:** `spec/services/identity/enrollment_service_spec.rb` (10)

**Likely cause:** TOTP/OTP verification logic changed or test data doesn't match current implementation.

### Cluster 5: Password Reset (8 failures)

**File:** `spec/requests/passwords_spec.rb` (8)

**Likely cause:** Mailer delivery expectations changed.

### Cluster 6: Append-Only Triggers (6 failures)

**File:** `spec/db/append_only_triggers_spec.rb` (6)

**Likely cause:** SQL trigger tests need updating for schema changes.

---

## Coverage Gaps

### Controllers Without Request Specs (59)

| Module | Count | Controllers |
|--------|-------|-------------|
| Management | 25 | branches, roles, policies, approval_workflows, configurations, entry_templates, holidays, teams, departments, password_policies, users, user_role_assignments, settings, dashboard, audit_logs, alerts, searches, risk_monitoring, fraud_incidents, compliance_controls, evidences, system_health, permissions, AI (5 sub-controllers), base controllers |
| Treasury | 6 | vault_transfers, loans, savings_products, cash_sessions, cash_sessions/closings, deposits, searches |
| Portal | 5 | announcements, sessions, dashboard, enrollment, base, MFA |
| Loans | 4 | applications, loans, payments, products, searches |
| Equity | 2 | accounts, products |
| External | 2 | base, entry_templates |
| Other | 4 | member_transactions, health, home, MFA |

### Models Without Unit Specs (53)

| Module | Count | Models |
|--------|-------|--------|
| AI | 7 | agent, agent_run, recommendation, observation, digest, and related |
| Management | 30+ | audit_log, branch, department, team, role, policy, approval_workflow, approval_request, approval, configuration, entry_template, holiday, alert, search, risk_monitoring, fraud_incident, compliance_control, evidence, system_health_snapshot, branch_performance_snapshot, permission, role_permission, user_role_assignment, and more |
| Lending | 5 | loan_payment, loan_product_version, loan_application, loan_collateral, loan_aging |
| Equity | 3 | account, product, transaction |
| Security | 3 | trusted_device, backup_code, mfa_attempt_log |
| Concerns | 4 | append_only_override, auto_audit, record_authorization, cooperative_scoped |

### Services Without Specs (56)

| Module | Count | Services |
|--------|-------|----------|
| AI | 13 | banking_copilot, prompt_builder, context_builder, action_router, branch_manager, all tools |
| Security | 4 | session_tracking, password_policy, password_history, account_lockout |
| Management | 10+ | system_health, risk_monitoring, audit_log, alert, approval_workflow, permission, policy_engine, configuration, branch_performance |
| MFA | 1 | totp_service |
| Treasury | 3 | cash_session, depositor_resolver, vault_transfer |
| Messaging | 3 | facebook_provider, ses_provider, sendgrid_provider |
| Summary | 4 | profile_summary, savings_summary, loan_summary, recent_activity |

---

## Pending Tests (10)

All entire spec files or focused specs:

- `spec/concurrency/concurrency_locking_spec.rb` — 2 pending
- `spec/models/compliance/control_spec.rb` — 1 pending (entire file)
- `spec/models/compliance/evidence_spec.rb` — 1 pending (entire file)
- `spec/models/fraud/incident_spec.rb` — 1 pending (entire file)
- `spec/models/fraud/rule_spec.rb` — 1 pending (entire file)
- `spec/models/security/password_history_spec.rb` — 1 pending (entire file)
- `spec/models/security/password_policy_spec.rb` — 1 pending (entire file)
- `spec/services/equity/buy_shares_service_spec.rb` — 2 pending

Each pending test should be evaluated: fix and implement, or remove if no longer relevant.

---

## Infrastructure Gaps

| Gap | Impact | Fix |
|-----|--------|-----|
| No `webmock` / `vcr` | External module tests fail on real HTTP calls | Add gems, record cassettes |
| No `timecop` | Time-sensitive tests use ad-hoc date math | Add gem, freeze time in relevant specs |
| `cooperative_context.rb` is global `before(:each)` | Masks cooperative creation, implicit in all tests | Convert to explicitly included context |
| Bullet gem not in test group | N+1 queries not detected in CI | Add `bullet` gem |
| No `rubocop-rspec` | Inconsistent test style | Add gem and configure |

---

## Remediation Plan

### Phase 1: Stabilize Existing Tests

Per cluster, repeat:
1. Run focused test file → isolate first failure
2. Determine root cause (not symptom)
3. Fix
4. Verify single test passes
5. Run full cluster
6. Commit with message referencing the fix

**Order:** accounting balance → external → messaging → identity → passwords → triggers

### Phase 2: Add Test Infrastructure

- Add `webmock` + `vcr` to Gemfile
- Add `timecop` to Gemfile
- Remove or fix all pending tests
- Move `cooperative_context.rb` from global to explicit

### Phase 3: Model Specs for Untested Modules

Priority order: security → lending → equity → management → AI → concerns

### Phase 4: Controller Request Specs

Priority order: treasury → portal → loans → equity → management → external

Each controller spec needs:
- `index` returns 200
- `show` returns 200 for valid record, 404 for invalid
- `create` returns 201/302 with valid params, 422 with invalid
- `update` returns 200/302 with valid params, 422 with invalid
- `destroy` returns 302/204
- Unauthorized access returns 302/403

### Phase 5: Playwright E2E

Per feature: happy path, validation, permissions, edge cases, regression (5 files per feature) following existing patterns in `tests/`.

---

## Test Run Commands

```
# Run all tests
bin/rails db:test:prepare && bin/rspec

# Single file
bin/rspec spec/path/to/file_spec.rb

# Single example (line number)
bin/rspec spec/path/to/file_spec.rb:42

# Failure cluster
bin/rspec spec/requests/accounting/
bin/rspec spec/models/external/ spec/requests/external/
bin/rspec spec/models/messaging/ spec/services/messaging/
bin/rspec spec/services/identity/
bin/rspec spec/requests/passwords_spec.rb
bin/rspec spec/db/
```
