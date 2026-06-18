module Management
  class AlertService < ActiveInteraction::Base
    string :alert_type
    string :severity, default: "info"
    string :title
    string :message, default: nil
    string :source, default: nil
    object :triggered_by, class: Object, default: nil

    def execute
      alert = Management::Alert.create!(
        alert_type: alert_type,
        severity: severity,
        title: title,
        message: message,
        source: source,
        triggered_by: triggered_by,
        status: "active"
      )

      notify_subscribers(alert)

      alert
    end

    private

    def notify_subscribers(alert)
      subscriptions = Management::AlertSubscription.active
        .where(alert_type: alert_type)

      subscriptions.each do |sub|
        case sub.channel
        when "in_app"
        when "dashboard"
        when "email"
        when "sms"
        end
      end
    end
  end
end
