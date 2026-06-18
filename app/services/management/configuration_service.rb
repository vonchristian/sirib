module Management
  class ConfigurationService < ActiveInteraction::Base
    string :key
    hash :value
    object :configurable, class: Object, default: nil
    object :changed_by, class: "User", default: nil
    string :change_reason, default: nil

    def execute
      config = Management::Configuration.find_or_initialize_by(
        key: key,
        configurable: configurable
      )

      old_value = config.value.dup
      old_version = config.version

      config.value = value
      config.changed_by = changed_by
      config.status = "draft"
      config.version = old_version + 1
      config.save!

      Management::ConfigurationVersion.create!(
        configuration: config,
        version: config.version,
        value: value,
        changed_by: changed_by,
        change_reason: change_reason
      )

      Management::AuditLogService.run!(action: "configuration_updated",
        auditable: config,
        actor: changed_by,
        changes: { before: { key => old_value }, after: { key => value } })

      config
    end

    def self.approve(config, approved_by:)
      config.update!(
        status: "active",
        approved_by: approved_by,
        approved_at: Time.current
      )

      Management::AuditLogService.run!(action: "configuration_approved",
        auditable: config,
        actor: approved_by)
    end
  end
end
