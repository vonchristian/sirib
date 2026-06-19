class CreateMessagingSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :messaging_channels do |t|
      t.string :name, null: false
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :messaging_channels, :name, unique: true

    create_table :messaging_providers do |t|
      t.references :channel, null: false, foreign_key: { to_table: :messaging_channels }
      t.string :name, null: false
      t.jsonb :config, default: {}
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :messaging_providers, [:channel_id, :name], unique: true
    add_index :messaging_providers, :enabled

    create_table :messaging_messages do |t|
      t.string :message_type, null: false
      t.string :recipient_type, null: false
      t.bigint :recipient_id, null: false
      t.jsonb :payload, default: {}
      t.string :status, default: "pending", null: false
      t.datetime :scheduled_at
      t.timestamps
    end

    add_index :messaging_messages, :message_type
    add_index :messaging_messages, :status
    add_index :messaging_messages, [:recipient_type, :recipient_id]

    create_table :messaging_message_deliveries do |t|
      t.references :message, null: false, foreign_key: { to_table: :messaging_messages }
      t.references :channel, null: false, foreign_key: { to_table: :messaging_channels }
      t.references :provider, foreign_key: { to_table: :messaging_providers }
      t.string :status, default: "queued", null: false
      t.integer :attempts_count, default: 0
      t.text :last_error
      t.string :provider_message_id
      t.datetime :sent_at
      t.datetime :delivered_at
      t.timestamps
    end

    add_index :messaging_message_deliveries, :status
    add_index :messaging_message_deliveries, [:message_id, :channel_id]

    create_table :messaging_provider_webhooks do |t|
      t.references :provider, null: false, foreign_key: { to_table: :messaging_providers }
      t.string :event_type, null: false
      t.jsonb :payload, default: {}
      t.datetime :processed_at
      t.timestamps
    end

    add_index :messaging_provider_webhooks, :event_type
    add_index :messaging_provider_webhooks, [:provider_id, :event_type], unique: true
  end
end