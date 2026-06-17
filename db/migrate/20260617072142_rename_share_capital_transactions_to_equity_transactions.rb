class RenameShareCapitalTransactionsToEquityTransactions < ActiveRecord::Migration[8.0]
  def change
    rename_table :share_capital_transactions, :equity_transactions
  end
end
