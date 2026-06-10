class AddAncestryToLedgers < ActiveRecord::Migration[8.0]
  def change
    add_column :ledgers, :ancestry, :string
    add_index :ledgers, :ancestry
  end
end
