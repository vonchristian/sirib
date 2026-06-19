TOTP-Based MFA System (Rails 8 Core Banking)
1. Overview

This system implements Time-based One-Time Password (TOTP) as a second authentication factor for a Rails 8 core banking platform. The design prioritizes:

Strong security (banking-grade)
Low user friction
Risk-based adaptive authentication (not always-on OTP prompts)
Fast, predictable user experience

TOTP is used as a step-up authentication mechanism, not a mandatory step for every interaction.

2. Goals
Primary Goals
Secure user authentication using TOTP (RFC 6238 standard)
Prevent unauthorized access even if password is compromised
Reduce OTP fatigue through intelligent prompting
Support auditability for compliance (banking-grade logging)
UX Goals
Minimize OTP prompts for trusted users/devices
Reduce login friction for daily operations
Keep OTP flow under 10–15 seconds end-to-end
Avoid repeated OTP requests within a session
3. Non-Goals
SMS OTP (explicitly excluded)
Hardware security keys (future phase)
Biometric authentication
Fully passwordless login
4. User Roles
Role	Description	MFA Requirement
Teller	Basic transactions	Conditional TOTP
Manager	Approvals + overrides	Frequent TOTP
Auditor	Read-only + reports	Minimal TOTP
Admin	System configuration	Strict TOTP
5. Functional Requirements
5.1 TOTP Enrollment (Setup)
Flow
User navigates to Security Settings
System generates TOTP secret
System shows QR code
User scans QR using authenticator app
User enters verification code
System confirms setup
Requirements
Generate RFC-compliant TOTP secret (Base32)
Encrypt secret at rest (Rails encrypted attributes)
QR code provisioning URI format:
otpauth://totp/{issuer}:{user_email}?secret={secret}&issuer={issuer}
Acceptance Criteria
Secret is never shown again after setup
QR code is generated dynamically
Setup requires successful OTP verification before activation
5.2 Login Flow (Adaptive MFA)
Flow Decision Tree
Password correct?
  ├── No → Reject
  └── Yes →
        Is device trusted?
            ├── Yes → Login success (skip OTP)
            └── No →
                  Require TOTP → verify → login
Trusted Device Rules

A device is trusted if:

Previously verified successfully with TOTP
Same browser fingerprint hash
Not expired (default: 14–30 days)
No high-risk signals
Acceptance Criteria
Returning trusted devices bypass OTP
New devices always require OTP
OTP step adds < 1 extra screen in flow
5.3 Step-Up Authentication (Critical Feature)

TOTP is required ONLY for high-risk actions:

Trigger Events
Fund transfer above threshold
Adding new payee
Changing security settings
Loan approval actions
Admin configuration changes
Flow
User action → risk engine → require OTP → verify → proceed
Acceptance Criteria
OTP prompt appears as modal (no full page redirect)
Session remains active during OTP challenge
OTP required only once per risk session window (default: 5–15 min)
5.4 OTP Verification
Requirements
6-digit numeric code
Valid window: ±1 time step (30–60 seconds tolerance max)
Single-use per session
Rate-limited attempts
Security Rules
Max 5 attempts per 10 minutes per user
Lock MFA after repeated failures (15 minutes cooldown)
Log all attempts (success + failure)
5.5 Trusted Device Management

Users can:

View active trusted devices
Revoke individual devices
Revoke all devices
Device Data Stored
Device hash (fingerprint)
Last login timestamp
IP range (optional)
User agent hash
6. Non-Functional Requirements
Security
OTP secret encrypted at rest (AES-256)
No OTP reuse across sessions
Secure session binding
Audit logs immutable
Performance
OTP verification < 50ms
No external API dependencies
Works offline once enrolled
Reliability
OTP system must function without third-party services
Must survive server restarts without state loss
7. UX Requirements (Critical for adoption)
Reduce Friction Principles
No OTP on every login for trusted devices
No OTP loops (stay in same screen)
Auto-submit OTP on 6 digits
Paste support enabled
Clear error messaging (not technical)
UX Rules
OTP screen timeout: none (until session expires)
Do not force logout after failed OTP
Always allow retry in same modal
8. System Architecture (Rails 8)
Models
User
has_one :mfa_setting
MfaSetting
otp_secret_encrypted
otp_enabled
last_verified_at
TrustedDevice
user_id
device_fingerprint_hash
last_used_at
expires_at
MfaAttemptLog
user_id
success/failure
ip_address
user_agent
timestamp
9. API Endpoints
MFA Setup
POST /mfa/setup
GET  /mfa/qrcode
POST /mfa/verify_setup
Login Flow
POST /auth/login
POST /auth/mfa/verify
Step-Up Auth
POST /auth/mfa/challenge
POST /auth/mfa/verify_stepup
Device Management
GET    /devices
DELETE /devices/:id
DELETE /devices
10. Risk-Based Authentication Engine
Rules Engine
Condition	Action
Trusted device + normal login	Skip OTP
New device	Require OTP
High-value transaction	Require OTP
Admin action	Require OTP
Suspicious IP	Require OTP + cooldown
11. Logging & Audit Requirements

Every MFA event must log:

user_id
action type (login / step-up)
success/failure
IP address
device fingerprint
timestamp

Logs must be:

immutable (append-only)
queryable for compliance
12. Error Handling
Common cases
Case	Response
Wrong OTP	"Invalid code, try again"
Expired OTP	"Code expired, generate a new one"
Too many attempts	"Temporarily locked, try again later"

No technical error messages exposed.

13. Rollout Plan
Phase 1
Basic TOTP login MFA
No device trust
Phase 2
Trusted device system
Step-up authentication
Phase 3
Risk scoring enhancements
Admin policies per role
14. Success Metrics
OTP success rate > 95%
OTP completion time < 15 seconds median
< 20% OTP prompts for returning users
Zero successful brute-force MFA bypass attempts
Reduced login drop-off rate vs baseline
15. Key Design Principle (Important)

Security should be invisible until it is necessary.

TOTP is not a gate at every door—it is a checkpoint at the moments that matter.