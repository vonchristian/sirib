class RemoveParentFromLedgers < ActiveRecord::Migration[8.0]
  def change
    remove_column :ledgers, :parent_id, :bigint
  end
end
