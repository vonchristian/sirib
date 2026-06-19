Facebook Messenger Delivery Use Case (Messaging System)
1. Overview

This PRD defines how the Messaging System is used to deliver messages via Facebook Messenger.

It does NOT introduce new models or systems.

Messenger is treated as a channel implementation inside the Messaging domain, just like Email.

2. Dependency

This PRD fully depends on the existing Messaging System:

Reused Models
Message
MessageDelivery
Channel
Provider
ProviderWebhook

No new models are introduced.

3. Goals
Primary Goals
Enable transactional messaging via Facebook Messenger
Support onboarding, alerts, and notifications
Provide opt-in controlled communication
Ensure delivery tracking and auditability
Secondary Goals
Support Facebook Page messaging integration
Maintain compliance with Messenger platform rules
Allow provider switching without code changes
4. Non-Goals
Human customer support chat system
AI chatbot (future phase)
SMS integration
Marketing or promotional messaging
Group chat functionality
5. Core Principle

Messenger is a notification delivery channel, not a chat system.

All messages are:

system-generated
transactional
auditable
non-conversational (MVP scope)
6. Messenger Flow (End-to-End)
Business Event (e.g. Account Blocked)
        ↓
Message created (type: block_notice)
        ↓
MessageDelivery created (channel: messenger)
        ↓
Channel = messenger loaded
        ↓
Provider = Facebook Messenger API
        ↓
Message sent via Facebook Graph API
        ↓
Webhook updates delivery status
        ↓
MessageDelivery updated (sent/delivered/read)
7. Messenger-Specific Rules
7.1 Opt-in Requirement

A member MUST have an active Messenger connection:

PSID (Page Scoped ID) must exist
Member must have initiated conversation OR opted in via link
If member has no PSID → do not send messenger messages

Fallback behavior:

Message is marked as failed_by_policy
7.2 Channel Constraint
MessageDelivery.channel = messenger
AND Channel.enabled = true
AND Provider.enabled = true
7.3 Messaging Window Rule (IMPORTANT)

Messenger platform rule:

Free-form messages allowed only within 24-hour window after user interaction

After 24 hours:

only approved message types allowed (restricted templates)

System must enforce this:

If outside 24-hour window → block or downgrade message type
8. Provider Layer (Messenger Execution)

Messenger provider is implemented via:

Facebook Graph API Provider
class FacebookMessengerProvider
  def self.send(delivery)
    message = delivery.message

    FacebookGraphAPI.send_message(
      psid: message.recipient.messenger_psid,
      text: render_template(message.message_type, message.payload)
    )
  end
end
9. Channel Configuration

Messenger is defined in Channel table:

Channel:
- name: messenger
- enabled: true

Provider linked:

Provider:
- name: facebook
- channel_id: messenger
- config:
    page_access_token
    app_secret
10. Message Types (Messenger Use Cases)

Allowed Messenger message types:

10.1 Onboarding
member_activation
account_access_enabled
10.2 Security
login_alert
account_blocked
password_reset
10.3 Notifications
loan_due_reminder
approval_status_update
11. Delivery Flow (Implementation)
Trigger
MessageDispatcher.call(
  type: "account_blocked",
  recipient: member,
  payload: { reason: "fraud_check" },
  channels: [:messenger]
)
Processing
DeliveryProcessor.call(message_delivery)
Execution (Messenger branch)
case provider.name
when "facebook"
  FacebookMessengerProvider.send(delivery)
end
12. Failure Handling

Failures may occur due to:

no PSID
expired messaging window
invalid page token
API rate limits

System behavior:

mark MessageDelivery as failed
store last_error
do not retry indefinitely (Messenger-specific rule)
13. Webhook Handling

Facebook sends events:

message_delivered
message_read
messaging_opt_out

System must:

update MessageDelivery.status
maintain delivery lifecycle accuracy
14. Security Requirements
Facebook App Secret verification required
Webhook signature validation mandatory
No sensitive banking data in message body
All payloads logged securely (sanitized)
15. Business Rules
Messenger is OPTIONAL channel
Must always be explicitly enabled per member
Cannot override Email as primary channel
No conversational logic in MVP
Strictly system-to-user notifications only
16. Observability

Must track:

sent messages
delivery status (sent, delivered, read)
failures (no PSID, window expired)
provider errors
17. Success Criteria
100% Messenger messages flow through Messaging system
No direct Facebook API calls outside provider layer
All deliveries are auditable via MessageDelivery
Opt-in enforcement works correctly
Webhook updates correctly reflect delivery state
18. Future Enhancements (Out of Scope)
chatbot / AI assistant
human support inbox
rich media templates (images, buttons)
interactive flows (buttons, quick replies)
multi-agent support system
Final Summary

This PRD defines Messenger as:

A controlled, opt-in, transactional notification channel inside the Messaging System

It ensures:

strict separation from business logic
compliance with Messenger platform rules
auditability through MessageDelivery
provider abstraction via Facebook API provider