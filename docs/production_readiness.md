# Production Readiness Checklist

> Audit date: July 2026
> Current deployment: DigitalOcean 2GB droplet, Kamal, PostgreSQL accessory

---

## 1. SSL / HTTPS

| Item | Status | Action |
|------|--------|--------|
| `config.force_ssl` | `false` | Set to `false` + `config.assume_ssl = true` (Kamal proxy handles SSL) |
| SSL certificate | Not configured | Add Let's Encrypt via Kamal proxy or Cloudflare |
| `X-Forwarded-Proto` trust | Needs verification | Ensure middleware respects reverse proxy headers |

**Note:** SSL was disabled because it broke POST login. This must be tested end-to-end after re-enabling.

---

## 2. Host Header Security

**File:** `config/environments/production.rb:83`

```ruby
config.hosts << /\A\d+\.\d+\.\d+\.\d+\z/
```

Wildcard regex allows any IP address as a valid host header. Combined with no SSL, this enables DNS rebinding and host header injection.

**Fix:** Replace with explicit hostnames matching actual deployment domains (e.g., `config.hosts << "sirib.ph"`, `config.hosts << "app.sirib.ph"`).

---

## 3. Session Fixation

| Action | Files |
|--------|-------|
| Add `reset_session` on login | `sessions_controller.rb`, `mfa_controller.rb`, `portal/sessions_controller.rb` |
| Add `reset_session` on logout | Same files |
| Admin cookie `secure` flag | `concerns/authentication.rb:102` |

See `docs/security.md` for details.

---

## 4. Authorization

| Item | Status | Details |
|------|--------|---------|
| Management controllers | 25 missing `require_permission!` | See `docs/authorization.md` |
| Financial controllers | 15 have no authorization | All treasury, equity, lending, accounting |
| Branch isolation | None | All queries return ALL branches' data |
| Ad-hoc role checks | `treasurer?` pattern in vault_transfers | Replace with `require_permission!` |

---

## 5. Database Integrity

| Item | Status | Details |
|------|--------|---------|
| Foreign keys | 6 missing | See `docs/database.md` |
| Polymorphic indexes | 4 missing | `alerts`, `approval_requests`, `audit_logs`, `policies` |
| Integer overflow risk | 9+ columns use `integer` instead of `bigint` | Polymorphic `_id` columns |
| `accounts.created_by_id` type | `uuid` instead of `bigint` | Cannot reference `users(id)` |
| Nested set columns | Declared but not maintained | `management_branches` |

---

## 6. Webhook Security

| Item | Status |
|------|--------|
| Authentication | Skipped (no auth) |
| Parameter sanitization | `params.permit!` — unrestricted |
| Signature verification | None |
| IP whitelisting | None |

**Fix:** Implement HMAC signature verification matching the provider's scheme. Restrict to known IPs. Permit only expected parameters.

---

## 7. User Enumeration

Login error messages reveal whether an account exists (locked/inactive states are distinguishable from "user not found").

**Fix:** Use a single generic error message for all authentication failure paths.

---

## 8. Rate Limiting

| Endpoint | Rate Limit | Status |
|----------|------------|--------|
| Admin login | `rate_limit to: 20, within: 20.seconds` | ✓ Present |
| Portal login | `rate_limit to: 10, within: 3.minutes` | ✓ Present (but no account lockout) |
| Enrollment TOTP | None | Missing — vulnerable to brute force |
| Admin + Portal global | `Rack::Attack` | Check if configured |

---

## 9. Monitoring & Alerting

| Item | Status | Action |
|------|--------|--------|
| Error tracking | Not checked | Consider Sentry or similar |
| Production logging | Not checked | Verify log levels, log rotation |
| Health check endpoint | Route exists (`/health`) | Verify returns 200 |
| Database monitoring | Not checked | Verify PG connection pooling, slow query logging |

---

## 10. Background Jobs

| Item | Status |
|------|--------|
| Queue adapter | Solid Queue (configured in `config/queue.yml`) |
| Job concurrency | 2 threads, processes via `JOB_CONCURRENCY` |
| Failed job handling | Not checked |
| Idempotency keys | Present (`IdempotencyKey` model with unique constraint) |

**Verify:** Dead job queue monitoring, retry strategy, alerting on failed jobs.

---

## 11. Backup & Recovery

| Item | Status |
|------|--------|
| Database backups | Not checked |
| Point-in-time recovery | Not checked |
| Backup frequency | Not checked |
| Restore test | Not checked |

---

## 12. Security Headers

| Header | Status |
|--------|--------|
| `Content-Security-Policy` | Not checked |
| `X-Frame-Options` | Not checked |
| `X-Content-Type-Options` | Not checked |
| `Strict-Transport-Security` | Requires SSL first |
| `Referrer-Policy` | Not checked |

**Fix:** Add via middleware or Kamal proxy config after SSL is enabled.

---

## 13. Dependency Audit

| Item | Command |
|------|---------|
| Ruby gem vulnerabilities | `bin/brakeman --no-pager` |
| JavaScript audit | `bin/importmap audit` |
| Outdated gems | `bundle outdated` |

Run these regularly (at minimum before each production deploy).

---

## Pre-Launch Verification Script

```bash
# 1. Security scan
bin/brakeman --no-pager

# 2. JS dependency audit
bin/importmap audit

# 3. Run all tests
bin/rails db:test:prepare && bin/rspec

# 4. Run E2E tests
npm run test:e2e

# 5. Verify health endpoint
curl -I https://sirib.ph/health

# 6. Verify login flow
curl -c /tmp/cookies -X POST https://sirib.ph/session \
  -d "email=admin@sirib.ph&password=password123" \
  -w "%{http_code}" -o /dev/null
# Expected: 302 redirect to /dashboard/manager

# 7. Verify SSL
curl -I https://sirib.ph

# 8. Check security headers
curl -I https://sirib.ph | grep -i "security\|frame\|content-type"
```
