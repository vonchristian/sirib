module Messaging
  class MessageDelivery < ApplicationRecord
    self.table_name = "messaging_message_deliveries"
    include CooperativeScoped

    belongs_to :message, class_name: "Messaging::Message"
    belongs_to :channel, class_name: "Messaging::Channel"
    belongs_to :provider, class_name: "Messaging::Provider", optional: true

    validates :status, presence: true

    enum :status, {
      queued: Messaging::DELIVERY_STATUS_QUEUED,
      sent: Messaging::DELIVERY_STATUS_SENT,
      delivered: Messaging::DELIVERY_STATUS_DELIVERED,
      failed: Messaging::DELIVERY_STATUS_FAILED,
      retrying: Messaging::DELIVERY_STATUS_RETRYING
    }, predicate: true

    scope :pending, -> { where(status: [ Messaging::DELIVERY_STATUS_QUEUED, Messaging::DELIVERY_STATUS_RETRYING ]) }
    scope :failed, -> { where(status: Messaging::DELIVERY_STATUS_FAILED) }

    def completed?
      sent? || delivered?
    end

    def increment_attempts!
      increment!(:attempts_count)
    end

    def mark_sent!(provider_message_id: nil)
      update!(status: :sent, sent_at: Time.current, provider_message_id: provider_message_id)
    end

    def mark_delivered!
      update!(status: :delivered, delivered_at: Time.current)
    end

    def mark_failed!(error)
      update!(status: :failed, last_error: error)
    end

    def mark_retrying!(error)
      update!(status: :retrying, last_error: error)
    end
  end
end
