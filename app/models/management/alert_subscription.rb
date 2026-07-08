module Management
  class AlertSubscription < ApplicationRecord
    self.table_name = "management_alert_subscriptions"
    include CooperativeScoped

    belongs_to :user

    validates :alert_type, :channel, presence: true
    validates :alert_type, uniqueness: { scope: [ :user_id, :channel ] }

    enum :channel, { email: "email", sms: "sms", in_app: "in_app", dashboard: "dashboard" }
  end
end
