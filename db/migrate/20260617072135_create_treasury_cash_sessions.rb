class CreateTreasuryCashSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :treasury_cash_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cash_account, null: false, foreign_key: { to_table: :accounts }
      t.date :date, null: false
      t.string :status, null: false, default: "open"
      t.datetime :opened_at, null: false
      t.datetime :closed_at
      t.decimal :beginning_balance_cents, precision: 15, scale: 2
      t.decimal :ending_balance_cents, precision: 15, scale: 2
      t.text :notes
      t.timestamps
    end

    add_index :treasury_cash_sessions, [:user_id, :cash_account_id, :date], unique: true, name: "idx_cash_sessions_on_user_account_date"
  end
end
