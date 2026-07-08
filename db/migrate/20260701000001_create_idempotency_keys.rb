class CreateIdempotencyKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :idempotency_keys do |t|
      t.string :key, null: false
      t.references :cooperative, null: false, foreign_key: true
      t.string :service, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :idempotency_keys, [ :key, :cooperative_id ], unique: true
    add_index :idempotency_keys, :expires_at
  end
end
