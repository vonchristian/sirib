class RemoveBalanceColumnsFromSavingsTables < ActiveRecord::Migration[8.0]
  def change
    remove_column :treasury_savings_accounts, :balance_cents, :decimal
    remove_column :treasury_savings_accounts, :balance_currency, :string

    remove_column :treasury_savings_transactions, :balance_before_cents, :decimal
    remove_column :treasury_savings_transactions, :balance_after_cents, :decimal
  end
end
