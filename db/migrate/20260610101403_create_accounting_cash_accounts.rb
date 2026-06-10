class CreateAccountingCashAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounting_cash_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end

    add_index :accounting_cash_accounts, [:user_id, :account_id], unique: true
  end
end
