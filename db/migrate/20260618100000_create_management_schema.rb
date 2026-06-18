class CreateManagementSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :management_branches do |t|
      t.references :cooperative, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.text :address
      t.string :contact_number
      t.string :status, default: "active", null: false
      t.references :parent, foreign_key: { to_table: :management_branches }
      t.integer :lft
      t.integer :rgt
      t.integer :depth, default: 0
      t.integer :children_count, default: 0
      t.timestamps
    end
    add_index :management_branches, :code, unique: true

    create_table :management_departments do |t|
      t.references :branch, null: false, foreign_key: { to_table: :management_branches }
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.timestamps
    end
    add_index :management_departments, [:branch_id, :code], unique: true

    create_table :management_teams do |t|
      t.references :department, null: false, foreign_key: { to_table: :management_departments }
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    create_table :management_roles do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.integer :rank, default: 0, null: false
      t.timestamps
    end
    add_index :management_roles, :code, unique: true

    create_table :management_permissions do |t|
      t.string :action, null: false
      t.string :subject, null: false
      t.text :description
      t.timestamps
    end
    add_index :management_permissions, [:action, :subject], unique: true

    create_table :management_role_permissions do |t|
      t.references :role, null: false, foreign_key: { to_table: :management_roles }
      t.references :permission, null: false, foreign_key: { to_table: :management_permissions }
      t.jsonb :constraints, default: {}
      t.timestamps
    end
    add_index :management_role_permissions, [:role_id, :permission_id], unique: true

    create_table :management_role_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: { to_table: :management_roles }
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.references :department, foreign_key: { to_table: :management_departments }
      t.date :active_from, default: -> { "CURRENT_DATE" }, null: false
      t.date :active_until
      t.timestamps
    end

    create_table :management_policies do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :category, null: false
      t.string :scope
      t.string :status, default: "active", null: false
      t.integer :version, default: 1, null: false
      t.jsonb :config, default: {}
      t.string :target_entity_type
      t.bigint :target_entity_id
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.timestamps
    end
    add_index :management_policies, :code, unique: true
    add_index :management_policies, [:target_entity_type, :target_entity_id]

    create_table :management_policy_rules do |t|
      t.references :policy, null: false, foreign_key: { to_table: :management_policies }
      t.string :field, null: false
      t.string :operator, null: false
      t.string :value, null: false
      t.string :effect, default: "deny", null: false
      t.timestamps
    end

    create_table :management_approval_workflows do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :category, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :management_approval_workflows, :code, unique: true

    create_table :management_approval_workflow_steps do |t|
      t.references :approval_workflow, null: false, foreign_key: { to_table: :management_approval_workflows }
      t.integer :sequence, null: false
      t.references :approver_role, foreign_key: { to_table: :management_roles }
      t.references :approver_user, foreign_key: { to_table: :users }
      t.bigint :threshold_cents_min
      t.bigint :threshold_cents_max
      t.string :condition
      t.timestamps
    end
    add_index :management_approval_workflow_steps, [:approval_workflow_id, :sequence], unique: true

    create_table :management_approval_requests do |t|
      t.string :requestable_type, null: false
      t.bigint :requestable_id, null: false
      t.references :workflow, null: false, foreign_key: { to_table: :management_approval_workflows }
      t.string :status, default: "pending", null: false
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.integer :current_step, default: 1, null: false
      t.text :reason
      t.timestamps
    end
    add_index :management_approval_requests, [:requestable_type, :requestable_id]
    add_index :management_approval_requests, :status

    create_table :management_approvals do |t|
      t.references :approval_request, null: false, foreign_key: { to_table: :management_approval_requests }
      t.references :step, null: false, foreign_key: { to_table: :management_approval_workflow_steps }
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false
      t.text :comment
      t.datetime :signed_at, null: false, default: -> { "NOW()" }
      t.timestamps
    end

    create_table :management_configurations do |t|
      t.string :key, null: false
      t.jsonb :value, default: {}, null: false
      t.integer :version, default: 1, null: false
      t.string :status, default: "draft", null: false
      t.string :configurable_type
      t.bigint :configurable_id
      t.references :changed_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.timestamps
    end
    add_index :management_configurations, [:key, :configurable_type, :configurable_id], unique: true, name: "idx_mgmt_configs_on_key_and_configurable"

    create_table :management_configuration_versions do |t|
      t.references :configuration, null: false, foreign_key: { to_table: :management_configurations }
      t.integer :version, null: false
      t.jsonb :value, default: {}, null: false
      t.references :changed_by, foreign_key: { to_table: :users }
      t.text :change_reason
      t.timestamps
    end
    add_index :management_configuration_versions, [:configuration_id, :version], unique: true

    create_table :management_alerts do |t|
      t.string :alert_type, null: false
      t.string :severity, default: "info", null: false
      t.string :title, null: false
      t.text :message
      t.string :source
      t.string :status, default: "active", null: false
      t.string :triggered_by_type
      t.bigint :triggered_by_id
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :management_alerts, [:triggered_by_type, :triggered_by_id]
    add_index :management_alerts, :status
    add_index :management_alerts, :alert_type

    create_table :management_alert_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :alert_type, null: false
      t.string :channel, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end
    add_index :management_alert_subscriptions, [:user_id, :alert_type, :channel], unique: true, name: "idx_mgmt_alert_subs_on_user_type_channel"

    create_table :management_audit_logs do |t|
      t.string :auditable_type
      t.bigint :auditable_id
      t.string :action, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.string :actor_role
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.string :ip_address
      t.text :user_agent
      t.jsonb :before_state
      t.jsonb :after_state
      t.jsonb :approval_chain
      t.string :config_version
      t.datetime :created_at, null: false
    end
    add_index :management_audit_logs, [:auditable_type, :auditable_id]
    add_index :management_audit_logs, :action
    add_index :management_audit_logs, :created_at

    create_table :management_branch_performance_snapshots do |t|
      t.references :branch, null: false, foreign_key: { to_table: :management_branches }
      t.date :snapshot_date, null: false
      t.jsonb :metrics, default: {}, null: false
      t.timestamps
    end
    add_index :management_branch_performance_snapshots, [:branch_id, :snapshot_date], unique: true, name: "idx_mgmt_branch_perf_on_branch_date"

    create_table :management_risk_indicators do |t|
      t.references :branch, foreign_key: { to_table: :management_branches }
      t.string :indicator_type, null: false
      t.decimal :value, precision: 20, scale: 4
      t.decimal :threshold, precision: 20, scale: 4
      t.string :status, default: "normal", null: false
      t.date :as_of_date, null: false, default: -> { "CURRENT_DATE" }
      t.timestamps
    end
    add_index :management_risk_indicators, [:branch_id, :indicator_type, :as_of_date], unique: true, name: "idx_mgmt_risk_indicators_on_branch_type_date"

    create_table :management_system_health_snapshots do |t|
      t.string :metric_name, null: false
      t.decimal :value, precision: 20, scale: 4
      t.string :unit
      t.string :status, default: "healthy", null: false
      t.datetime :captured_at, null: false, default: -> { "NOW()" }
      t.timestamps
    end
    add_index :management_system_health_snapshots, [:metric_name, :captured_at]
  end
end
