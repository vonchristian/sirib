module Messaging
  class Channel < ApplicationRecord
    self.table_name = "messaging_channels"

    has_many :providers, class_name: "Messaging::Provider", dependent: :restrict_with_error
    has_many :message_deliveries, class_name: "Messaging::MessageDelivery", dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: true

    scope :enabled, -> { where(enabled: true) }

    def email?
      name == Messaging::CHANNEL_EMAIL
    end

    def messenger?
      name == Messaging::CHANNEL_MESSENGER
    end
  end
end
