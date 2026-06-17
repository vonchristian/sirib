class RenameShareCapitalAccountsToEquityAccounts < ActiveRecord::Migration[8.0]
  def change
    rename_table :share_capital_accounts, :equity_accounts
  end
end
