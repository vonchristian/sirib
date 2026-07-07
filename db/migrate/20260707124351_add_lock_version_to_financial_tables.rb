class AddLockVersionToFinancialTables < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :lock_version, :integer, default: 0, null: false
    add_column :amount_lines, :lock_version, :integer, default: 0, null: false
    add_column :running_balances, :lock_version, :integer, default: 0, null: false
    add_column :loans, :lock_version, :integer, default: 0, null: false
    add_column :loan_payments, :lock_version, :integer, default: 0, null: false
    add_column :treasury_savings_accounts, :lock_version, :integer, default: 0, null: false
    add_column :treasury_savings_transactions, :lock_version, :integer, default: 0, null: false
    add_column :equity_accounts, :lock_version, :integer, default: 0, null: false
    add_column :equity_transactions, :lock_version, :integer, default: 0, null: false
    add_column :treasury_cash_sessions, :lock_version, :integer, default: 0, null: false
  end
end
