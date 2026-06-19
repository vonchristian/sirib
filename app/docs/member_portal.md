Member Enrollment & Online Banking Access (Cooperative Banking Portal)
1. Overview

This feature enables newly approved members of a cooperative to gain secure, seamless access to an online banking portal immediately after membership approval.

The portal is view-only for v1, focusing on transparency and engagement:

Savings
Share capital
Loan balances
Repayment schedules

No fund transfers or payments in this phase.

The system prioritizes:

Secure onboarding
Low-friction access
Proactive member engagement via coops
2. Goals
Business Goals
Digitize post-approval onboarding
Reduce manual credential distribution
Improve member engagement with financial visibility
Enable cooperatives to proactively communicate with members
User Goals (Members)
Quickly access their account after approval
Secure login without confusion or friction
View financial status anytime
Non-Goals (v1)
No fund transfers
No bill payments
No loan applications
No external integrations (SMS banking, etc.)
3. Actors
Member – Approved cooperative member
Cooperative Admin – Approves membership and triggers enrollment
Banking Portal System – Core system providing access
Identity Layer (Internal) – Handles authentication and permissions
4. User Journey
A. Membership Approval → Enrollment Trigger
Member application is approved in cooperative system
System auto-generates:
Member portal account
Enrollment token (one-time use)
Member receives:
Email or SMS notification (configurable)
Enrollment link
B. First-Time Access / Enrollment
Member clicks enrollment link
System prompts:
Set up authentication method
TOTP (Authenticator App) REQUIRED
Member scans QR code into:
Google Authenticator / Microsoft Authenticator / Authy
System verifies TOTP
Member sets:
Password (optional depending on security policy)
Account activated
C. Subsequent Logins
Member logs in via:
Member ID + Password
TOTP verification (mandatory second factor)
5. Features
5.1 Enrollment System
One-time enrollment token (expires in 24–72 hours)
Secure link generation
Token invalidation after use
5.2 Authentication (Security-First)
Primary Authentication
Member ID + Password
Multi-Factor Authentication
TOTP-based MFA (RFC 6238)
QR-based onboarding
Security Requirements
Rate limiting on login attempts
Account lockout after failed attempts
Encrypted secret storage for TOTP seed
Session timeout (idle + absolute)
5.3 Member Dashboard (Read-Only Banking View)
Savings Account
Current balance
Transaction summary (optional future enhancement)
Share Capital
Total shares
Dividend history (future-ready placeholder)
Loans
Outstanding balance
Interest breakdown (optional)
Loan status
Repayment Schedule
Upcoming due dates
Amount due
Overdue indicators
5.4 Cooperative Outreach Channel

A lightweight internal messaging capability:

Cooperative can send announcements:
Loan reminders
Share capital updates
General notices
Displayed in member dashboard
No external chat required
6. Data Model (Simplified)
Member
id
member_id
email
phone
status (pending, approved, active, suspended)
Auth
password_hash
totp_secret_encrypted
last_login_at
EnrollmentToken
token
member_id
expires_at
used_at
Accounts
savings_balance
share_capital_balance
Loans
principal
outstanding_balance
next_due_date
7. Security Requirements
Must Have
TOTP MFA mandatory for all logins
Encrypted secrets at rest
Secure token-based enrollment
HTTPS everywhere
Audit logs for:
Login attempts
Enrollment events
MFA resets
Threat Mitigations
Brute force protection
Token replay prevention
Session hijacking protection
Device/session invalidation option
8. UX Requirements
Enrollment must complete in < 3 minutes
Mobile-first design (majority users in rural/cooperative environments)
Minimal form fields
Clear QR-based TOTP onboarding
No confusing banking jargon
9. E2E Test Strategy (Playwright)
9.1 Enrollment Flow
Given approved member
When enrollment link is opened
Then QR code is displayed
And TOTP setup completes successfully
9.2 Login Flow
Valid credentials + TOTP → success
Invalid password → error
Invalid TOTP → blocked attempt
9.3 Security Tests
Expired token cannot be used
Reused token is rejected
Locked account cannot log in
9.4 Dashboard Access
Member sees correct balances
Member cannot access other member data
9.5 Outreach Messages
Coop message appears in dashboard
Message respects ordering and timestamps
10. Rails 8 Implementation Notes
Suggested Stack
Rails 8 (Hotwire enabled)
TOTP: rotp gem
Encryption: Rails credentials + ActiveRecord encryption
Sessions: cookie-based + server invalidation
Background jobs: Solid Queue
Key Modules
Identity::EnrollmentService
Identity::TotpService
Members::DashboardQuery
Coop::BroadcastMessageService
11. Future Enhancements (Post-v1)
Push notifications (loan due reminders)
SMS fallback authentication
Mobile app (Flutter or React Native)
Transaction history ledger view
AI assistant for member queries
Loan application workflow
12. Success Metrics
90%+ enrollment completion rate
<5% login failure due to MFA issues
Reduced manual onboarding support requests
Increased monthly member logins