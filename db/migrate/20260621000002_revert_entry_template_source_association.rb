class RevertEntryTemplateSourceAssociation < ActiveRecord::Migration[8.0]
  def change
    remove_column :entries, :source_type, :string
    remove_column :entries, :source_id, :bigint
    add_reference :entry_templates, :entry, null: true, foreign_key: { to_table: :entries }
  end
end
