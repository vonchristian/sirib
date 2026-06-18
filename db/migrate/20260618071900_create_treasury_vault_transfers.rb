class CreateTreasuryVaultTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :treasury_vault_transfers do |t|
      t.references :cash_session, null: false, foreign_key: { to_table: :treasury_cash_sessions }
      t.string :direction, null: false
      t.decimal :amount_cents, precision: 15, scale: 2, null: false
      t.text :description
      t.timestamps
    end
  end
end
