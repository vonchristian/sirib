module Messaging
  class Provider < ApplicationRecord
    self.table_name = "messaging_providers"

    belongs_to :channel, class_name: "Messaging::Channel"
    has_many :message_deliveries, class_name: "Messaging::MessageDelivery", dependent: :restrict_with_error
    has_many :provider_webhooks, class_name: "Messaging::ProviderWebhook", dependent: :restrict_with_error

    validates :name, presence: true
    validates :name, uniqueness: { scope: :channel_id }

    scope :enabled, -> { where(enabled: true) }

    def sendgrid?
      name == "sendgrid"
    end

    def ses?
      name == "ses"
    end

    def facebook?
      name == "facebook"
    end
  end
end
