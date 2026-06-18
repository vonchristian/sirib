class AddCountsToTreasuryCashSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :treasury_cash_sessions, :counts, :jsonb, default: []
  end
end
