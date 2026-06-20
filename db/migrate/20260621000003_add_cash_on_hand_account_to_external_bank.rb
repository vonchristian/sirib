class AddCashOnHandAccountToExternalBank < ActiveRecord::Migration[8.0]
  def change
    add_reference :external_banks, :cash_on_hand_account, null: true, foreign_key: { to_table: :accounts }
  end
end
