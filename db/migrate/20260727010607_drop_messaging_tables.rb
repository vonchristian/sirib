class DropMessagingTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :messaging_provider_webhooks
    drop_table :messaging_message_deliveries
    drop_table :messaging_providers
    drop_table :messaging_messages
    drop_table :messaging_channels
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
