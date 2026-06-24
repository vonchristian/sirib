class AddCooperativeIdToRestructureTables < ActiveRecord::Migration[8.0]
  def change
    add_reference :loan_schedules, :cooperative, foreign_key: true
    add_reference :loan_links, :cooperative, foreign_key: true
    add_reference :loan_events, :cooperative, foreign_key: true
    add_reference :loan_restructure_cases, :cooperative, foreign_key: true
  end
end
