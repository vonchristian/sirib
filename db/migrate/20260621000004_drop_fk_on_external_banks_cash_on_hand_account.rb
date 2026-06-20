class DropFkOnExternalBanksCashOnHandAccount < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :external_banks, column: :cash_on_hand_account_id
  end
end
