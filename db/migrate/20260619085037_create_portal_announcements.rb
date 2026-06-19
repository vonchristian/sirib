class CreatePortalAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :portal_announcements do |t|
      t.references :cooperative, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.string :status, default: "draft", null: false
      t.datetime :published_at
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :portal_announcements, :status
    add_index :portal_announcements, :published_at
  end
end
