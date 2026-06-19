Email Delivery Use Case (Built on Messaging System)
1. Overview

This PRD defines how the Messaging System is used specifically for Email delivery.

It does NOT introduce new models or systems.

It only defines:

how email messages are created
how email deliveries are processed
how providers are used for email channel
how onboarding and transactional emails behave
2. Dependency

This PRD depends entirely on the Messaging System:

Existing Models (REUSED)
Message
MessageDelivery
Channel
Provider
ProviderWebhook

No new models introduced.

3. Goals
Primary Goals
Enable transactional email delivery via Messaging system
Support onboarding, security, and system notifications
Ensure provider-agnostic email sending
Allow provider switching without code changes
Secondary Goals
Support templated emails
Ensure retryable delivery
Ensure full audit trail via Messaging system
4. Non-Goals
Messenger implementation (separate PRD)
SMS or other channels
Marketing email campaigns
Email UI editor
Standalone email system
5. Core Principle

Email is a use case of Messaging, not a system.

All emails must go through:

Message → MessageDelivery → Channel(email) → Provider

6. Email Flow (End-to-End)
Business Event (e.g. Member Created)
        ↓
Message created (type: member_activation)
        ↓
MessageDelivery created (channel: email)
        ↓
Channel = email loaded
        ↓
Provider resolved (SendGrid / SES)
        ↓
Email sent via provider
        ↓
ProviderWebhook receives status (optional)
        ↓
MessageDelivery updated
7. Email-Specific Rules
7.1 Message Type Mapping

Email uses Message.message_type as template key:

Examples:

member_activation
password_reset
block_notice
messenger_opt_in
7.2 Channel Constraint

Email delivery only happens if:

Channel.name == "email"
AND Channel.enabled == true
7.3 Provider Selection

Provider is resolved dynamically:

Provider where:
- channel_id = email channel
- enabled = true

No hardcoded provider logic in business code.

8. Email Sending Process (Implementation View)
8.1 Trigger

All email sending starts from Messaging:

MessageDispatcher.call(
  type: "member_activation",
  recipient: member,
  payload: { token: "abc123" },
  channels: [:email]
)
8.2 Delivery Processing

Handled by Messaging worker:

DeliveryProcessor.call(message_delivery)
8.3 Provider Execution (Email Only Branch)

Inside Messaging system:

case provider.name
when "sendgrid"
  SendgridProvider.send(delivery)
when "ses"
  SesProvider.send(delivery)
end
9. Email Provider Responsibilities

Email providers ONLY handle:

formatting email request
calling external API
returning provider message id

They do NOT:

know business logic
know Message structure beyond payload
manage retries (Messaging system handles that)
10. Templates (Email Usage)

Email uses Messaging payload system:

Example:
Message:
  type: member_activation
  payload:
    name: "Juan"
    link: "https://app.com/activate"

Provider uses:

template_key = message_type
variables = payload
11. Failure Handling

Email failures are handled via Messaging:

retry via Solid Queue
update MessageDelivery.status
store last_error

No email-specific retry logic exists.

12. Provider Switching Requirement

Email provider can be changed without code changes:

Example:

Before:

email → SendGrid

After:

email → AWS SES

Only update:

Provider table (channel=email)

No deployment required.

13. Observability

Must support:

email sent count
email failure rate
provider performance comparison (future)
full trace via MessageDelivery
14. Security Requirements
no API keys in code
provider credentials stored securely
webhook signature validation required
no sensitive data in logs
15. Business Rules
Email is the PRIMARY onboarding channel
All activation flows depend on email delivery
Email is always triggered through Messaging system only
No direct mailer calls allowed
16. Success Criteria
100% email traffic flows through Messaging system
Providers can be swapped without code changes
All email deliveries are auditable via MessageDelivery
No email logic exists outside Messaging domain
17. Future Enhancements (Out of Scope)
email queue dashboard UI
email retry admin panel
email analytics
template editor
multi-provider failover per email channel
Final Summary

This PRD defines:

Email as a first-class use case of the Messaging System, not a separate system.

It guarantees:

strict reuse of Messaging models
clean separation of concerns
provider-agnostic email delivery
banking-grade traceability