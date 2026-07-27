class DropFraudAndComplianceTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :management_alert_subscriptions
    drop_table :management_alerts
    drop_table :compliance_evidences
    drop_table :compliance_controls
    drop_table :fraud_incidents
    drop_table :fraud_rules
    drop_table :management_risk_indicators
    drop_table :management_system_health_snapshots
    drop_table :management_branch_performance_snapshots
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
