class DropExternalAndPortalTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :reconciliation_results
    drop_table :external_bank_transaction_allocations
    drop_table :external_bank_transactions
    drop_table :external_bank_documents
    drop_table :external_bank_accounts
    drop_table :external_banks
    drop_table :portal_announcements
    drop_table :portal_enrollment_tokens
    drop_table :portal_sessions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
