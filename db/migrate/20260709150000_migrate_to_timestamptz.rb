class MigrateToTimestamptz < ActiveRecord::Migration[8.0]
  TIMESTAMP_TABLES = {
    accounting_cash_accounts: %i[created_at updated_at],
    accounts: %i[created_at updated_at],
    active_storage_attachments: %i[created_at],
    active_storage_blobs: %i[created_at],
    ai_agent_runs: %i[started_at completed_at created_at updated_at],
    ai_agents: %i[created_at updated_at],
    ai_digests: %i[generated_at created_at updated_at],
    ai_observations: %i[detected_at resolved_at created_at updated_at],
    ai_recommendations: %i[dismissed_at completed_at acknowledged_at created_at updated_at],
    amount_lines: %i[created_at updated_at],
    ar_internal_metadata: %i[created_at updated_at],
    backup_codes: %i[used_at created_at updated_at],
    compliance_controls: %i[created_at updated_at],
    compliance_evidences: %i[verified_at expires_at created_at updated_at],
    cooperatives: %i[created_at updated_at],
    entries: %i[posted_at reversed_at created_at updated_at],
    entry_template_lines: %i[created_at updated_at],
    entry_templates: %i[created_at updated_at],
    equity_accounts: %i[opened_at created_at updated_at],
    equity_products: %i[created_at updated_at],
    equity_transactions: %i[posted_at created_at updated_at],
    external_bank_accounts: %i[last_synced_at created_at updated_at],
    external_bank_documents: %i[created_at updated_at],
    external_bank_transaction_allocations: %i[created_at updated_at],
    external_bank_transactions: %i[created_at updated_at],
    external_banks: %i[created_at updated_at],
    fraud_incidents: %i[resolved_at created_at updated_at],
    fraud_rules: %i[created_at updated_at],
    idempotency_keys: %i[expires_at created_at updated_at],
    ledgers: %i[created_at updated_at],
    loan_aging_groups: %i[created_at updated_at],
    loan_aging_snapshots: %i[created_at updated_at],
    loan_agings: %i[calculated_at created_at updated_at],
    loan_applications: %i[created_at updated_at],
    loan_charges: %i[created_at updated_at],
    loan_co_makers: %i[created_at updated_at],
    loan_collaterals: %i[created_at updated_at],
    loan_events: %i[created_at updated_at],
    loan_links: %i[created_at updated_at],
    loan_payments: %i[created_at updated_at],
    loan_products: %i[created_at updated_at],
    loan_repayment_schedules: %i[created_at updated_at],
    loan_restructure_cases: %i[submitted_at reviewed_at executed_at created_at updated_at],
    loan_schedules: %i[superseded_at created_at updated_at],
    loans: %i[created_at updated_at],
    management_alert_subscriptions: %i[created_at updated_at],
    management_alerts: %i[resolved_at created_at updated_at],
    management_approval_requests: %i[created_at updated_at],
    management_approval_workflow_steps: %i[created_at updated_at],
    management_approval_workflows: %i[created_at updated_at],
    management_approvals: %i[signed_at created_at updated_at],
    management_audit_logs: %i[created_at],
    management_branch_performance_snapshots: %i[created_at updated_at],
    management_branches: %i[created_at updated_at],
    management_configuration_versions: %i[created_at updated_at],
    management_configurations: %i[approved_at created_at updated_at],
    management_departments: %i[created_at updated_at],
    management_holidays: %i[created_at updated_at],
    management_permissions: %i[created_at updated_at],
    management_policies: %i[approved_at created_at updated_at],
    management_policy_rules: %i[created_at updated_at],
    management_risk_indicators: %i[created_at updated_at],
    management_role_assignments: %i[created_at updated_at],
    management_role_permissions: %i[created_at updated_at],
    management_roles: %i[created_at updated_at],
    management_system_health_snapshots: %i[captured_at created_at updated_at],
    management_teams: %i[created_at updated_at],
    member_addresses: %i[created_at updated_at],
    member_identifications: %i[created_at updated_at],
    members: %i[otp_verified_at last_login_at created_at updated_at],
    membership_applications: %i[created_at updated_at],
    messaging_channels: %i[created_at updated_at],
    messaging_message_deliveries: %i[sent_at delivered_at created_at updated_at],
    messaging_messages: %i[scheduled_at created_at updated_at],
    messaging_provider_webhooks: %i[processed_at created_at updated_at],
    messaging_providers: %i[created_at updated_at],
    mfa_attempt_logs: %i[created_at updated_at],
    portal_announcements: %i[published_at created_at updated_at],
    portal_enrollment_tokens: %i[expires_at used_at created_at updated_at],
    portal_sessions: %i[revoked_at last_activity_at mfa_verified_at created_at updated_at],
    running_balances: %i[created_at updated_at],
    saved_filters: %i[created_at updated_at],
    security_password_histories: %i[created_at updated_at],
    security_password_policies: %i[created_at updated_at],
    sessions: %i[created_at updated_at revoked_at last_activity_at mfa_verified_at],
    treasury_cash_sessions: %i[opened_at closed_at created_at updated_at],
    treasury_savings_accounts: %i[opened_at closed_at created_at updated_at],
    treasury_savings_product_interest_rates: %i[created_at updated_at],
    treasury_savings_products: %i[created_at updated_at],
    treasury_savings_transactions: %i[posted_at created_at updated_at],
    treasury_time_deposit_products: %i[created_at updated_at],
    treasury_time_deposits: %i[opened_at closed_at created_at updated_at],
    treasury_vault_transfers: %i[approved_at created_at updated_at],
    treasury_vouchers: %i[posted_at created_at updated_at],
    trusted_devices: %i[last_used_at expires_at created_at updated_at],
    users: %i[created_at updated_at otp_verified_at locked_at password_changed_at last_seen_at]
  }.freeze

  def up
    execute("SET timezone = 'UTC'")

    TIMESTAMP_TABLES.each do |table, columns|
      columns.each do |column|
        change_column table, column, :timestamptz
      end
    end
  end

  def down
    execute("SET timezone = 'UTC'")

    TIMESTAMP_TABLES.reverse_each do |table, columns|
      columns.each do |column|
        change_column table, column, :timestamp
      end
    end
  end
end