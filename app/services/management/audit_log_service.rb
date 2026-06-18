module Management
  class AuditLogService < ActiveInteraction::Base
    string :action
    object :auditable, class: Object, default: nil
    object :actor, class: "User", default: nil
    hash :metadata, default: {}
    hash :changes, default: {}

    def execute
      Management::AuditLog.create!(
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
    end
  end
end
