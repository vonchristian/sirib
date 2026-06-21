module Messaging
  class ProviderWebhook < ApplicationRecord
    self.table_name = "messaging_provider_webhooks"
    include CooperativeScoped

    belongs_to :provider, class_name: "Messaging::Provider"

    validates :event_type, presence: true
    validates :event_type, uniqueness: { scope: :provider_id, conditions: -> { where(processed_at: nil) } }

    scope :unprocessed, -> { where(processed_at: nil) }
    scope :by_event_type, ->(type) { where(event_type: type) }

    def payload_data
      @payload_data ||= (payload || {}).with_indifferent_access
    end

    def process!
      update!(processed_at: Time.current)
    end

    def processed?
      processed_at.present?
    end
  end
end
