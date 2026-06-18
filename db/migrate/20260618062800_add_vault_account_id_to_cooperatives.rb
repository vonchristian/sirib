class AddVaultAccountIdToCooperatives < ActiveRecord::Migration[7.2]
  def change
    add_reference :cooperatives, :vault_account, null: true, foreign_key: { to_table: :accounts }
  end
end
