class CreateExternalBankingSchema < ActiveRecord::Migration[8.0]
  def up
    create_table :external_banks do |t|
      t.string :name, null: false
      t.string :code
      t.string :country, null: false, default: "Philippines"
      t.string :status, null: false, default: "active"
      t.bigint :cash_on_hand_ledger_id
      t.bigint :interest_income_ledger_id
      t.timestamps
    end
    add_index :external_banks, :name
    add_index :external_banks, :code
    add_index :external_banks, :status

    create_table :external_bank_accounts do |t|
      t.references :external_bank, null: false, foreign_key: true, index: false
      t.string :account_name, null: false
      t.text :account_number_encrypted
      t.string :account_type, null: false
      t.string :currency, null: false, default: "PHP"
      t.decimal :current_balance, precision: 20, scale: 4, default: 0
      t.decimal :current_balance_cents, precision: 20, scale: 4, default: 0
      t.string :current_balance_currency, limit: 3, null: false, default: "PHP"
      t.datetime :last_synced_at
      t.string :status, null: false, default: "active"
      t.bigint :cash_on_hand_account_id
      t.bigint :interest_income_account_id
      t.timestamps
    end
    add_index :external_bank_accounts, :external_bank_id
    add_index :external_bank_accounts, :status

    create_table :external_bank_documents do |t|
      t.references :external_bank_account, null: false, foreign_key: true, index: false
      t.string :document_type, null: false, default: "statement"
      t.date :period_start
      t.date :period_end
      t.string :processing_status, null: false, default: "pending"
      t.jsonb :metadata, default: {}
      t.text :error_message
      t.timestamps
    end
    add_index :external_bank_documents, :external_bank_account_id
    add_index :external_bank_documents, :processing_status

    create_table :external_bank_transactions do |t|
      t.references :external_bank_account, null: false, foreign_key: true, index: false
      t.references :external_bank_document, foreign_key: true, null: true, index: false
      t.date :transaction_date, null: false
      t.text :description, null: false
      t.string :reference_number
      t.decimal :amount, precision: 20, scale: 4, null: false
      t.decimal :amount_cents, precision: 20, scale: 4, null: false
      t.string :amount_currency, limit: 3, null: false, default: "PHP"
      t.string :direction, null: false
      t.decimal :running_balance, precision: 20, scale: 4
      t.decimal :running_balance_cents, precision: 20, scale: 4
      t.string :running_balance_currency, limit: 3, default: "PHP"
      t.string :hash_signature, null: false
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :external_bank_transactions, :external_bank_account_id
    add_index :external_bank_transactions, :external_bank_document_id
    add_index :external_bank_transactions, :transaction_date
    add_index :external_bank_transactions, :hash_signature, unique: true
    add_index :external_bank_transactions, [:external_bank_account_id, :transaction_date], name: "idx_ext_bank_tx_on_account_date"

    create_table :external_bank_transaction_allocations do |t|
      t.references :external_bank_transaction, null: false, foreign_key: true, index: false
      t.references :journal_entry, foreign_key: { to_table: :entries }, null: true, index: false
      t.decimal :allocated_amount, precision: 20, scale: 4, null: false
      t.decimal :allocated_amount_cents, precision: 20, scale: 4, null: false
      t.string :allocated_amount_currency, limit: 3, null: false, default: "PHP"
      t.string :status, null: false, default: "suggested"
      t.decimal :confidence_score, precision: 5, scale: 4
      t.references :created_by, foreign_key: { to_table: :users }, null: true, index: false
      t.timestamps
    end
    add_index :external_bank_transaction_allocations, :external_bank_transaction_id
    add_index :external_bank_transaction_allocations, :journal_entry_id
    add_index :external_bank_transaction_allocations, :created_by_id
    add_index :external_bank_transaction_allocations, :status
  end

  def down
    drop_table :external_bank_transaction_allocations
    drop_table :external_bank_transactions
    drop_table :external_bank_documents
    drop_table :external_bank_accounts
    drop_table :external_banks
  end
end