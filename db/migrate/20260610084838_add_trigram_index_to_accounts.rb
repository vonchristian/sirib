class AddTrigramIndexToAccounts < ActiveRecord::Migration[8.0]
  def change
    add_index :accounts, "name gin_trgm_ops, account_code gin_trgm_ops", using: :gin, name: "trgm_accounts_idx", if_not_exists: true
  end
end
