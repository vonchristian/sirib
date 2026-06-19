TOTP Multi-Factor Authentication (Bank-Grade) for Rails Core Banking System
1. Overview

Implement Time-based One-Time Password (TOTP) Multi-Factor Authentication (MFA) for a Rails 8 core banking platform. This is a mandatory second authentication factor after password login for all privileged and financial actions, with optional enforcement for all users depending on risk policy.

The system must comply with bank-grade security standards, be resistant to replay attacks, phishing resistance (within TOTP limits), and support secure secret lifecycle management.

2. Goals
Primary Goals
Secure user login with TOTP MFA after password authentication
Ensure MFA is required before granting session access
Support QR-code-based enrollment
Provide secure recovery mechanisms (backup codes)
Ensure cryptographically secure secret storage
Non-Goals
SMS-based OTP (explicitly excluded)
Push-based MFA (future enhancement)
Biometric authentication
3. Security Requirements (Bank-Grade)
3.1 Cryptographic Standards
Use RFC 6238 TOTP standard
6-digit codes
30-second time window
SHA-1 minimum (SHA-256 preferred if supported by client apps)
3.2 Secret Storage
OTP secret must be:
Encrypted at rest using Rails encryption (ActiveRecord::Encryption)
Never exposed after initial enrollment
Rotatable
3.3 Session Security
MFA must be completed BEFORE session is fully authenticated
Partial session state:
mfa_pending: true until verified
Session invalidation on MFA failure threshold exceeded
3.4 Rate Limiting
Max 5 failed MFA attempts per 10 minutes per user
Account lock or cooldown after threshold breach
3.5 Audit Logging

Log all events:

MFA setup
MFA success
MFA failure
Secret reset/regeneration
Backup code usage

Logs must include:

user_id
IP address
timestamp
device fingerprint (if available)
4. User Flow
4.1 Enrollment Flow (Setup MFA)
User navigates to Security Settings
Clicks “Enable Two-Factor Authentication”
System generates:
otp_secret
provisioning URI
Display QR code (for authenticator apps)
User scans using:
Google Authenticator
Microsoft Authenticator
Authy
User enters 6-digit verification code
System verifies code
MFA enabled
Generate 10 backup recovery codes
4.2 Login Flow
Step 1: Password authentication
User enters email + password
If valid → move to MFA challenge
Step 2: MFA challenge
System prompts /mfa/challenge
User enters 6-digit TOTP code
Step 3: Verification
If valid:
complete login session
mark mfa_verified: true
If invalid:
increment failed attempts
apply rate limiting rules
4.3 Recovery Flow

If user loses device:

Use backup recovery code (single-use)
OR admin-assisted reset (requires audit approval)
5. Technical Design (Rails 8)
5.1 Dependencies
gem "rotp"
gem "rqrcode"

Optional:

gem "active_record_encryption"
gem "rack-attack"
5.2 Database Schema
users table additions
otp_secret: string (encrypted)
otp_enabled: boolean, default: false
otp_verified_at: datetime
mfa_required: boolean, default: true
backup_codes table
user_id: references
code_digest: string
used_at: datetime
5.3 TOTP Service Object

app/services/mfa/totp_service.rb

Responsibilities:

Generate secret
Generate provisioning URI
Verify token
Time drift handling (+/- 1 step)
5.4 QR Code Generator
Use rqrcode

Encode provisioning URI:

otpauth://totp/BankApp:email@example.com?secret=XYZ&issuer=BankApp
5.5 Authentication Middleware

Add authentication gate:

before_action :require_mfa!

def require_mfa!
  return if current_user.mfa_verified?
  redirect_to mfa_challenge_path
end
5.6 MFA Session State

Session flags:

session[:user_id]
session[:mfa_verified] = true

Never allow full session without MFA flag.

6. API / Controller Structure
MFA Controller
GET /mfa/setup
POST /mfa/enable
GET /mfa/challenge
POST /mfa/verify
POST /mfa/disable (admin or user)
7. Security Controls
7.1 Brute Force Protection
Rate limit MFA attempts
Temporary lock after repeated failures
7.2 Secret Rotation
Allow regeneration of OTP secret
Immediately invalidate old tokens
7.3 Device Awareness (optional phase 2)
Track trusted devices
Require MFA only on new devices
8. UX Requirements
Clear step-by-step setup wizard
QR code + manual key fallback
Error messages must not leak security details
Show backup codes once only
Strong warnings before disabling MFA
9. Edge Cases
Clock drift (allow ±1 time step)
User changes phone
Lost access recovery
Multiple devices using same secret
Session timeout during MFA flow
10. Future Enhancements
Push-based MFA (WebAuthn / Passkeys)
Hardware security keys (FIDO2)
Adaptive MFA (risk-based triggers)
Geo-velocity detection
Transaction-level MFA (for withdrawals/transfers)
11. Acceptance Criteria
 User cannot access system without successful MFA if enabled
 TOTP verification works with Google Authenticator / Authy
 QR enrollment works reliably
 Backup codes function and are single-use
 Secrets are encrypted at rest
 Rate limiting prevents brute force attempts
 All MFA events are audited
 Session cannot be hijacked without MFA completion
12. Implementation Priority
TOTP core (ROTP integration)
MFA enrollment flow
Login MFA challenge gate
Backup codes
Rate limiting
Audit logging
Admin recovery flow