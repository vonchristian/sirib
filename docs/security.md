# Security Audit & Roadmap

> Audit date: July 2026
> Status: Findings + remediation plan for opencode implementation.

---

## Tier 1: Critical (Ship-Blocking)

These issues must be resolved before any real cooperative uses the system.

### 1.1 Session Fixation — No `reset_session`

`reset_session` is never called anywhere in the codebase.

**Affected files:**

| File | Lines | Issue |
|------|-------|-------|
| `app/controllers/sessions_controller.rb` | 64, 74 | `create` and `destroy` — no `reset_session` before `start_new_session_for` / `terminate_session` |
| `app/controllers/mfa_controller.rb` | 67 | `verify` — no `reset_session` before `start_new_session_for` |
| `app/controllers/portal/sessions_controller.rb` | 30, 36 | `create` and `destroy` — no `reset_session` before `start_new_portal_session_for` / `terminate_portal_session` |
| `app/controllers/concerns/authentication.rb` | — | `start_new_session_for` helper assumes session is clean |
| `app/controllers/concerns/portal_authentication.rb` | — | Same pattern for portal |

**Impact:** An attacker who plants a known session ID cookie can have the victim authenticate against it, giving the attacker a valid session.

**Fix:** Add `reset_session` at the top of every `create` (login) and `destroy` (logout) action before establishing the new session.

### 1.2 Production SSL Disabled

**File:** `config/environments/production.rb:29`

```ruby
config.force_ssl = false  # HTTPS not enforced
config.assume_ssl = false
```

**Impact:** All traffic including credentials, session cookies, and financial data transmitted in plaintext.

**Fix:** Set `config.assume_ssl = true` (Kamal proxy terminates SSL). Ensure `X-Forwarded-Proto` headers are trusted.

### 1.3 Admin Session Cookie Missing `secure` Flag

**File:** `app/controllers/concerns/authentication.rb:102`

```ruby
cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
```

Missing `secure: Rails.env.production?`. Portal session cookie (`portal_authentication.rb:80`) correctly includes it — this is an inconsistency.

**Impact:** Session cookie transmitted over unencrypted HTTP. Combined with `force_ssl = false`, enables trivial cookie theft on open networks.

**Fix:** Add `secure: Rails.env.production?` to match the portal implementation.

### 1.4 Webhook Unauthenticated Mass Assignment

**File:** `app/controllers/messaging/webhooks_controller.rb:51`

```ruby
def webhook_params
  if request.content_type == "application/json"
    JSON.parse(request.body.read).with_indifferent_access
  else
    params.permit!  # unrestricted mass assignment
  end
end
```

Controller also skips all auth:
```ruby
skip_before_action :require_authentication
skip_before_action :require_permission!, raise: false
```

**Impact:** An attacker who discovers the webhook URL can send arbitrary payloads into `Messaging::WebhookProcessor.call`, potentially leading to data corruption or code execution.

**Fix:** Implement webhook signature verification (HMAC) matching the provider's scheme. Permit only expected parameters.

---

## Tier 2: Medium

### 2.1 User Enumeration via Login Error Messages

**File:** `app/controllers/sessions_controller.rb`

- Line 13: `"Try another email address or password."` (user not found)
- Lines 23, 32: `"Account temporarily locked..."` / `"Your account has been #{user.status}..."` — reveals account exists
- Line 37: `"Try another email address or password."` (wrong password — same as not-found)

**Fix:** Use generic `"Invalid email or password."` for ALL failure paths.

### 2.2 MFA User ID in Session Without Validation

**File:** `app/controllers/sessions_controller.rb:60`

```ruby
session[:mfa_user_id] = user.id
```

After password auth succeeds but before MFA completes, the user ID is stored unvalidated. Attacker with planted `session[:mfa_user_id]` could potentially skip password auth.

**Fix:** Store a signed/encrypted timestamp alongside the user ID and verify it is < N minutes old.

### 2.3 Open Redirect on Login

**File:** `app/controllers/concerns/authentication.rb:79-81`

```ruby
def after_authentication_url
  session.delete(:return_to_after_authenticating) || after_sign_in_url
end
```

The `return_to` value comes from `request.url` and is used directly for redirect. Same pattern in `portal_authentication.rb:69`.

**Fix:** Validate redirect destination against a whitelist or only allow relative paths.

### 2.4 Portal Account Lockout Not Enforced

**File:** `app/controllers/portal/sessions_controller.rb:10-33`

Portal sessions `create` action has `rate_limit to: 10, within: 3.minutes` but does NOT check `Security::AccountLockoutService.locked?` before allowing authentication attempts. Admin sessions controller does this correctly.

**Fix:** Add `AccountLockoutService` checks to portal sessions controller.

### 2.5 Password Reset Token in Redirect URL

**File:** `app/controllers/passwords_controller.rb:24,32`

```ruby
redirect_to edit_password_path(params[:token]), alert: result.errors.first
```

On failure, the reset token is included in the redirect URL and leaks via `Referer` header.

**Fix:** Re-fetch the user from the token on error rather than passing it in the URL.

---

## Tier 3: Low

### 3.1 Enrollment Lockout is Session-Based

**File:** `app/controllers/portal/enrollment_controller.rb:79-107`

Lockout counter stored in `session[:portal_enrollment_failed_attempts]` — trivially bypassed by clearing cookies.

**Fix:** Move to database (keyed on member ID or IP). Use `rate_limit` DSL.

### 3.2 Enrollment IDOR

**File:** `app/controllers/portal/enrollment_controller.rb:34`

`complete` action looks up member by `session[:portal_enrollment_member_id]` without re-validating the enrollment token.

**Fix:** Re-validate token-member association in the `complete` action.

### 3.3 No Rate Limiting on Enrollment TOTP

**File:** `app/controllers/portal/enrollment_controller.rb:28-74`

No `rate_limit` on the enrollment `complete` action.

**Fix:** Add `rate_limit to: 5, within: 10.minutes`.

### 3.4 Floating-Point Money Conversions

Six controllers use `to_f * 100` for monetary values, causing precision errors:

| File | Line |
|------|------|
| `app/controllers/treasury/savings_accounts_controller.rb` | 196 |
| `app/controllers/treasury/cash_sessions_controller.rb` | 74 |
| `app/controllers/equity/accounts_controller.rb` | 161 |
| `app/controllers/member_transactions_controller.rb` | 154 |
| `app/controllers/loans/payments_controller.rb` | 7 |
| `app/controllers/accounting/entries_controller.rb` | 50 |

**Fix:** Use `BigDecimal(value) * 100` or `money-rails` parsing.

### 3.5 No CSRF Protection Configuration

`protect_from_forgery` is not explicitly declared anywhere. Rails 8 applies it by default in `ActionController::Base`, but the absence of an explicit declaration is a defense-in-depth concern.

**Fix:** Add `protect_from_forgery with: :exception` explicitly in `ApplicationController`.

### 3.6 File Upload Validation

**Files:** `app/controllers/external/documents_controller.rb:16-27`, `app/controllers/members_controller.rb:140-161`

No content-type validation, file size limits, or virus scanning on uploaded documents and profile images.

**Fix:** Add model-level validations on content type and size.

---

## Remediation Order

1. **Session fixation** — 5 `reset_session` calls, 5 files, 30 minutes
2. **SSL + cookie flags** — 2 config changes, 15 minutes
3. **Webhook auth** — 1 file, permit params + signature verification
4. **User enumeration** — 1 file, generic error message
5. **MFA validation** — store signed timestamp
6. **Open redirect** — whitelist validation
7. **Portal lockout** — add `AccountLockoutService`
8. **Password reset token** — re-fetch instead of URL param
9. **Floating-point money** — `BigDecimal` conversion across 6 controllers
10. **Remaining low-priority items**
