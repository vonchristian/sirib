class AddLedgerRefsToSavingsProductsAndAccountRefsToSavingsAccounts < ActiveRecord::Migration[8.0]
  def change
    add_reference :treasury_savings_products, :liability_ledger, foreign_key: { to_table: :ledgers }
    add_reference :treasury_savings_products, :interest_expense_ledger, foreign_key: { to_table: :ledgers }

    add_reference :treasury_savings_accounts, :liability_account, foreign_key: { to_table: :accounts }
    add_reference :treasury_savings_accounts, :interest_expense_account, foreign_key: { to_table: :accounts }
  end
end
