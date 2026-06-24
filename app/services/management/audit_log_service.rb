module Management
  class AuditLogService < ActiveInteraction::Base
    string :action
    object :auditable, class: Object, default: nil
    object :actor, class: "User", default: nil
    hash :metadata, default: {}
    hash :changes, default: {}

    def execute
      cooperative = Current.cooperative || actor&.cooperative
      record = Management::AuditLog.create!(
        cooperative: cooperative,
        auditable: auditable,
        action: action,
        actor: actor,
        actor_role: actor&.management_roles&.first&.code,
        branch: Current.branch,
        ip_address: Current.session&.ip_address,
        user_agent: Current.session&.user_agent,
        before_state: changes[:before]&.to_json,
        after_state: changes[:after]&.to_json,
        approval_chain: metadata[:approval_chain],
        config_version: metadata[:config_version],
        created_at: Time.current
      )

      publish_event(record, cooperative)
      record
    end

    private

    def publish_event(record, cooperative)
      event_name = case action
      when "login_success" then Security::EventBus::EVENTS[:login_success]
      when "login_blocked" then Security::EventBus::EVENTS[:login_blocked]
      when "logout" then Security::EventBus::EVENTS[:logout]
      when "create" then Security::EventBus::EVENTS[:audit_create]
      when "update" then Security::EventBus::EVENTS[:audit_update]
      when "destroy" then Security::EventBus::EVENTS[:audit_destroy]
      when "account_locked" then Security::EventBus::EVENTS[:account_locked]
      when "suspicious_activity" then Security::EventBus::EVENTS[:suspicious_activity]
      end

      return unless event_name

      ActiveSupport::Notifications.instrument(event_name, {
        audit_log_id: record.id,
        action: action,
        user_id: actor&.id,
        cooperative: cooperative,
        ip: record.ip_address,
        auditable_type: record.auditable_type,
        auditable_id: record.auditable_id
      }.merge(metadata))
    end
  end
end
