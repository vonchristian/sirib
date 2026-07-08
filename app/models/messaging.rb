module Messaging
  CHANNEL_EMAIL = "email".freeze
  CHANNEL_MESSENGER = "messenger".freeze

  MESSAGE_TYPES = %w[
    member_activation
    password_reset
    block_notice
  ].freeze

  MESSAGE_STATUS_PENDING = "pending".freeze
  MESSAGE_STATUS_PROCESSING = "processing".freeze
  MESSAGE_STATUS_COMPLETED = "completed".freeze
  MESSAGE_STATUS_FAILED = "failed".freeze

  DELIVERY_STATUS_QUEUED = "queued".freeze
  DELIVERY_STATUS_SENT = "sent".freeze
  DELIVERY_STATUS_DELIVERED = "delivered".freeze
  DELIVERY_STATUS_FAILED = "failed".freeze
  DELIVERY_STATUS_RETRYING = "retrying".freeze
end
