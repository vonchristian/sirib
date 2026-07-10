class AddReversalReasonToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :reversal_reason, :text
  end
end