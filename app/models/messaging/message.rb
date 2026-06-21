module Messaging
  class Message < ApplicationRecord
    self.table_name = "messaging_messages"
    include CooperativeScoped

    has_many :deliveries, class_name: "Messaging::MessageDelivery", dependent: :destroy

    validates :message_type, presence: true
    validates :recipient_type, presence: true
    validates :recipient_id, presence: true
    validates :status, presence: true

    enum :status, {
      pending: Messaging::MESSAGE_STATUS_PENDING,
      processing: Messaging::MESSAGE_STATUS_PROCESSING,
      completed: Messaging::MESSAGE_STATUS_COMPLETED,
      failed: Messaging::MESSAGE_STATUS_FAILED
    }, predicate: true

    scope :pending, -> { where(status: Messaging::MESSAGE_STATUS_PENDING) }
    scope :failed, -> { where(status: Messaging::MESSAGE_STATUS_FAILED) }

    def payload_data
      @payload_data ||= (payload || {}).with_indifferent_access
    end

    def mark_processing!
      update!(status: :processing)
    end

    def mark_completed!
      update!(status: :completed)
    end

    def mark_failed!
      update!(status: :failed)
    end

    def all_deliveries_completed?
      deliveries.all? { |d| d.completed? || d.failed? }
    end

    def any_delivery_failed?
      deliveries.any?(&:failed?)
    end
  end
end
