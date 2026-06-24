# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_06_24_101755) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "account_type", ["asset", "equity", "liability", "revenue", "expense"]

  create_table "accounting_cash_accounts", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_accounting_cash_accounts_on_account_id"
    t.index ["cooperative_id"], name: "index_accounting_cash_accounts_on_cooperative_id"
    t.index ["user_id", "account_id"], name: "index_accounting_cash_accounts_on_user_id_and_account_id", unique: true
  end

  create_table "accounts", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "ledger_id", null: false
    t.string "name", null: false
    t.string "account_code", null: false
    t.boolean "contra", default: false
    t.enum "account_type", null: false, enum_type: "account_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.boolean "postable"
    t.uuid "created_by_id"
    t.uuid "modified_by_id"
    t.index ["cooperative_id", "account_code"], name: "index_accounts_on_cooperative_id_and_account_code", unique: true
    t.index ["cooperative_id"], name: "index_accounts_on_cooperative_id"
    t.index ["ledger_id"], name: "index_accounts_on_ledger_id"
    t.index ["postable"], name: "index_accounts_on_postable"
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "amount_lines", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "entry_id", null: false
    t.bigint "account_id", null: false
    t.integer "amount_type", null: false
    t.integer "amount_cents", null: false
    t.string "amount_currency", limit: 3, default: "PHP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "entry_id"], name: "index_amount_lines_on_account_id_and_entry_id"
    t.index ["account_id"], name: "index_amount_lines_on_account_id"
    t.index ["cooperative_id"], name: "index_amount_lines_on_cooperative_id"
    t.index ["entry_id"], name: "index_amount_lines_on_entry_id"
  end

  create_table "backup_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code_digest", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "used_at"], name: "index_backup_codes_on_user_id_and_used_at"
    t.index ["user_id"], name: "index_backup_codes_on_user_id"
  end

  create_table "compliance_controls", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "category"
    t.string "frequency"
    t.boolean "active"
    t.jsonb "config"
    t.bigint "cooperative_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_compliance_controls_on_cooperative_id"
  end

  create_table "compliance_evidences", force: :cascade do |t|
    t.bigint "control_id", null: false
    t.string "status"
    t.string "evidence_type"
    t.jsonb "metadata"
    t.datetime "verified_at"
    t.string "verified_by_type"
    t.bigint "verified_by_id"
    t.datetime "expires_at"
    t.bigint "cooperative_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_id"], name: "index_compliance_evidences_on_control_id"
    t.index ["cooperative_id"], name: "index_compliance_evidences_on_cooperative_id"
    t.index ["verified_by_type", "verified_by_id"], name: "index_compliance_evidences_on_verified_by"
  end

  create_table "cooperatives", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.string "contact_number"
    t.string "registration_number"
    t.bigint "vault_account_id"
    t.string "status", default: "inactive", null: false
    t.string "locale", default: "en"
    t.string "timezone", default: "UTC"
    t.index ["vault_account_id"], name: "index_cooperatives_on_vault_account_id"
  end

  create_table "entries", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "reference_number", null: false
    t.text "description", null: false
    t.datetime "posted_at", null: false
    t.bigint "branch_id"
    t.string "status", default: "posted", null: false
    t.string "entry_type", default: "manual_entry", null: false
    t.string "source_module", default: "source_manual", null: false
    t.datetime "reversed_at"
    t.bigint "reversal_of_id"
    t.bigint "created_by_id"
    t.bigint "template_id"
    t.boolean "has_attachments", default: false, null: false
    t.boolean "inter_branch", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_entries_on_cooperative_id"
    t.index ["created_by_id"], name: "index_entries_on_created_by_id"
    t.index ["posted_at", "branch_id"], name: "index_entries_on_posted_at_and_branch_id"
    t.index ["posted_at"], name: "index_entries_on_posted_at"
    t.index ["reference_number"], name: "index_entries_on_reference_number", unique: true
    t.index ["reversal_of_id"], name: "index_entries_on_reversal_of_id"
    t.index ["source_module"], name: "index_entries_on_source_module"
    t.index ["status", "entry_type"], name: "index_entries_on_status_and_entry_type"
    t.index ["template_id"], name: "index_entries_on_template_id"
  end

  create_table "entry_template_lines", force: :cascade do |t|
    t.bigint "entry_template_id", null: false
    t.bigint "account_id", null: false
    t.string "direction", null: false
    t.string "amount_mode", default: "variable", null: false
    t.decimal "fixed_amount", precision: 20, scale: 4
    t.integer "sequence_index", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cooperative_id", null: false
    t.index ["account_id"], name: "index_entry_template_lines_on_account_id"
    t.index ["cooperative_id"], name: "index_entry_template_lines_on_cooperative_id"
    t.index ["entry_template_id"], name: "index_entry_template_lines_on_entry_template_id"
  end

  create_table "entry_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "entry_id"
    t.bigint "cooperative_id", null: false
    t.index ["cooperative_id"], name: "index_entry_templates_on_cooperative_id"
    t.index ["entry_id"], name: "index_entry_templates_on_entry_id"
    t.index ["is_active"], name: "index_entry_templates_on_is_active"
  end

  create_table "equity_accounts", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id", null: false
    t.bigint "share_product_id", null: false
    t.string "account_number", null: false
    t.string "status", default: "active", null: false
    t.datetime "opened_at", null: false
    t.bigint "opened_by_id", null: false
    t.string "branch"
    t.text "remarks"
    t.integer "shares_owned", default: 0, null: false
    t.integer "paid_up_shares", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "equity_account_id"
    t.index ["cooperative_id", "account_number"], name: "index_equity_accounts_on_cooperative_id_and_account_number", unique: true
    t.index ["cooperative_id"], name: "index_equity_accounts_on_cooperative_id"
    t.index ["equity_account_id"], name: "index_equity_accounts_on_equity_account_id"
    t.index ["member_id", "share_product_id"], name: "index_equity_accounts_on_member_id_and_share_product_id", unique: true
    t.index ["member_id"], name: "index_equity_accounts_on_member_id"
    t.index ["opened_by_id"], name: "index_equity_accounts_on_opened_by_id"
    t.index ["share_product_id"], name: "index_equity_accounts_on_share_product_id"
  end

  create_table "equity_products", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "product_code", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "share_type", default: 0, null: false
    t.string "status", default: "active", null: false
    t.date "effective_date"
    t.integer "price_per_share_cents", default: 0, null: false
    t.integer "minimum_required_shares", default: 1, null: false
    t.integer "maximum_allowed_shares"
    t.integer "minimum_initial_purchase", default: 1, null: false
    t.boolean "allow_fractional_shares", default: false, null: false
    t.boolean "redeemable", default: true, null: false
    t.boolean "dividend_eligible", default: true, null: false
    t.boolean "voting_rights", default: true, null: false
    t.bigint "equity_ledger_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id", "product_code"], name: "index_equity_products_on_cooperative_id_and_product_code", unique: true
    t.index ["cooperative_id"], name: "index_equity_products_on_cooperative_id"
    t.index ["equity_ledger_id"], name: "index_equity_products_on_equity_ledger_id"
  end

  create_table "equity_transactions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "share_capital_account_id", null: false
    t.integer "transaction_type", default: 0, null: false
    t.integer "shares", null: false
    t.integer "price_per_share_cents", null: false
    t.integer "total_amount_cents", null: false
    t.bigint "cash_account_id"
    t.bigint "entry_id"
    t.string "reference_number", null: false
    t.string "status", default: "completed", null: false
    t.datetime "posted_at", null: false
    t.bigint "posted_by_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_equity_transactions_on_cash_account_id"
    t.index ["cooperative_id"], name: "index_equity_transactions_on_cooperative_id"
    t.index ["entry_id"], name: "index_equity_transactions_on_entry_id"
    t.index ["posted_by_id"], name: "index_equity_transactions_on_posted_by_id"
    t.index ["reference_number"], name: "index_equity_transactions_on_reference_number", unique: true
    t.index ["share_capital_account_id"], name: "index_equity_transactions_on_share_capital_account_id"
  end

  create_table "external_bank_accounts", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "external_bank_id", null: false
    t.string "account_name", null: false
    t.text "account_number_encrypted"
    t.string "account_type", null: false
    t.string "currency", default: "PHP", null: false
    t.decimal "current_balance", default: "0.0"
    t.decimal "current_balance_cents", default: "0.0"
    t.string "current_balance_currency", default: "PHP", null: false
    t.datetime "last_synced_at"
    t.string "status", default: "active", null: false
    t.bigint "cash_on_hand_account_id"
    t.bigint "interest_income_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_on_hand_account_id"], name: "index_external_bank_accounts_on_cash_on_hand_account_id"
    t.index ["cooperative_id"], name: "index_external_bank_accounts_on_cooperative_id"
    t.index ["external_bank_id"], name: "index_external_bank_accounts_on_external_bank_id"
    t.index ["interest_income_account_id"], name: "index_external_bank_accounts_on_interest_income_account_id"
    t.index ["status"], name: "index_external_bank_accounts_on_status"
  end

  create_table "external_bank_documents", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "external_bank_account_id", null: false
    t.string "document_type", default: "statement", null: false
    t.date "period_start"
    t.date "period_end"
    t.string "processing_status", default: "pending", null: false
    t.jsonb "metadata", default: "{}"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_external_bank_documents_on_cooperative_id"
    t.index ["external_bank_account_id"], name: "index_external_bank_documents_on_external_bank_account_id"
    t.index ["processing_status"], name: "index_external_bank_documents_on_processing_status"
  end

  create_table "external_bank_transaction_allocations", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "external_bank_transaction_id", null: false
    t.bigint "journal_entry_id"
    t.decimal "allocated_amount", null: false
    t.decimal "allocated_amount_cents", null: false
    t.string "allocated_amount_currency", default: "PHP", null: false
    t.string "status", default: "suggested", null: false
    t.decimal "confidence_score"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_external_bank_transaction_allocations_on_cooperative_id"
    t.index ["created_by_id"], name: "index_external_bank_transaction_allocations_on_created_by_id"
    t.index ["external_bank_transaction_id"], name: "idx_on_external_bank_transaction_id_be9fd773f0"
    t.index ["journal_entry_id"], name: "idx_on_journal_entry_id_313b3a4665"
    t.index ["status"], name: "index_external_bank_transaction_allocations_on_status"
  end

  create_table "external_bank_transactions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "external_bank_account_id", null: false
    t.bigint "external_bank_document_id"
    t.date "transaction_date", null: false
    t.text "description", null: false
    t.string "reference_number"
    t.decimal "amount", null: false
    t.decimal "amount_cents", null: false
    t.string "amount_currency", default: "PHP", null: false
    t.string "direction", null: false
    t.decimal "running_balance"
    t.decimal "running_balance_cents"
    t.string "running_balance_currency", default: "PHP"
    t.string "hash_signature", null: false
    t.jsonb "metadata", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_external_bank_transactions_on_cooperative_id"
    t.index ["external_bank_account_id", "transaction_date"], name: "idx_on_external_bank_account_id_transaction_date_213f021c2b"
    t.index ["external_bank_account_id"], name: "index_external_bank_transactions_on_external_bank_account_id"
    t.index ["external_bank_document_id"], name: "index_external_bank_transactions_on_external_bank_document_id"
    t.index ["hash_signature"], name: "index_external_bank_transactions_on_hash_signature", unique: true
    t.index ["transaction_date"], name: "index_external_bank_transactions_on_transaction_date"
  end

  create_table "external_banks", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.string "code"
    t.string "country", default: "Philippines", null: false
    t.string "status", default: "active", null: false
    t.bigint "cash_on_hand_ledger_id"
    t.bigint "interest_income_ledger_id"
    t.bigint "cash_on_hand_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_on_hand_account_id"], name: "index_external_banks_on_cash_on_hand_account_id"
    t.index ["cash_on_hand_ledger_id"], name: "index_external_banks_on_cash_on_hand_ledger_id"
    t.index ["code"], name: "index_external_banks_on_code"
    t.index ["cooperative_id"], name: "index_external_banks_on_cooperative_id"
    t.index ["interest_income_ledger_id"], name: "index_external_banks_on_interest_income_ledger_id"
    t.index ["name"], name: "index_external_banks_on_name"
    t.index ["status"], name: "index_external_banks_on_status"
  end

  create_table "fraud_incidents", force: :cascade do |t|
    t.bigint "rule_id", null: false
    t.string "incident_type"
    t.string "severity"
    t.text "description"
    t.jsonb "metadata"
    t.string "actor_type", null: false
    t.bigint "actor_id", null: false
    t.datetime "resolved_at"
    t.string "resolved_by_type"
    t.bigint "resolved_by_id"
    t.string "resolution"
    t.bigint "cooperative_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_type", "actor_id"], name: "index_fraud_incidents_on_actor"
    t.index ["cooperative_id"], name: "index_fraud_incidents_on_cooperative_id"
    t.index ["resolved_by_type", "resolved_by_id"], name: "index_fraud_incidents_on_resolved_by"
    t.index ["rule_id"], name: "index_fraud_incidents_on_rule_id"
  end

  create_table "fraud_rules", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "rule_type"
    t.jsonb "config"
    t.string "severity"
    t.boolean "active"
    t.bigint "cooperative_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_fraud_rules_on_cooperative_id"
  end

  create_table "ledgers", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.string "account_code", null: false
    t.boolean "contra", default: false
    t.enum "account_type", null: false, enum_type: "account_type"
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_ledgers_on_ancestry"
    t.index ["cooperative_id", "account_code"], name: "index_ledgers_on_cooperative_id_and_account_code", unique: true
    t.index ["cooperative_id"], name: "index_ledgers_on_cooperative_id"
  end

  create_table "loan_applications", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id"
    t.bigint "loan_product_id"
    t.string "uuid", null: false
    t.string "status", default: "draft", null: false
    t.integer "current_step", default: 0
    t.decimal "amount_cents"
    t.string "amount_currency", default: "PHP"
    t.decimal "interest_rate"
    t.integer "term_months"
    t.date "submitted_at"
    t.date "approved_at"
    t.text "notes"
    t.jsonb "sources_of_income", default: "[]"
    t.string "reference_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_applications_on_cooperative_id"
    t.index ["loan_product_id"], name: "index_loan_applications_on_loan_product_id"
    t.index ["member_id"], name: "index_loan_applications_on_member_id"
    t.index ["reference_number"], name: "index_loan_applications_on_reference_number", unique: true
    t.index ["uuid"], name: "index_loan_applications_on_uuid", unique: true
  end

  create_table "loan_charges", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "loan_product_id", null: false
    t.string "name", null: false
    t.string "charge_type", default: "fixed", null: false
    t.decimal "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_charges_on_cooperative_id"
    t.index ["loan_product_id"], name: "index_loan_charges_on_loan_product_id"
  end

  create_table "loan_co_makers", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "loan_application_id", null: false
    t.bigint "member_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_co_makers_on_cooperative_id"
    t.index ["loan_application_id", "member_id"], name: "index_loan_co_makers_on_loan_application_id_and_member_id", unique: true
    t.index ["loan_application_id"], name: "index_loan_co_makers_on_loan_application_id"
    t.index ["member_id"], name: "index_loan_co_makers_on_member_id"
  end

  create_table "loan_collaterals", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "loan_application_id", null: false
    t.string "category", null: false
    t.string "name"
    t.text "description"
    t.decimal "assessed_value_cents"
    t.string "assessed_value_currency", default: "PHP"
    t.decimal "pin_lat"
    t.decimal "pin_lng"
    t.string "address"
    t.jsonb "details", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_collaterals_on_cooperative_id"
    t.index ["loan_application_id"], name: "index_loan_collaterals_on_loan_application_id"
  end

  create_table "loan_events", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.string "actor_type", null: false
    t.bigint "actor_id", null: false
    t.string "event_type", null: false
    t.string "status", default: "completed", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cooperative_id"
    t.index ["actor_type", "actor_id"], name: "index_loan_events_on_actor"
    t.index ["cooperative_id"], name: "index_loan_events_on_cooperative_id"
    t.index ["loan_id", "created_at"], name: "index_loan_events_on_loan_id_and_created_at"
    t.index ["loan_id", "event_type"], name: "index_loan_events_on_loan_id_and_event_type"
    t.index ["loan_id"], name: "index_loan_events_on_loan_id"
  end

  create_table "loan_links", force: :cascade do |t|
    t.bigint "from_loan_id", null: false
    t.bigint "to_loan_id", null: false
    t.string "link_type", null: false
    t.decimal "amount_cents", precision: 20, scale: 2, default: "0.0", null: false
    t.string "amount_currency", default: "PHP", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cooperative_id"
    t.index ["cooperative_id"], name: "index_loan_links_on_cooperative_id"
    t.index ["from_loan_id", "link_type"], name: "index_loan_links_on_from_loan_id_and_link_type"
    t.index ["from_loan_id", "to_loan_id"], name: "index_loan_links_on_from_loan_id_and_to_loan_id", unique: true
    t.index ["from_loan_id"], name: "index_loan_links_on_from_loan_id"
    t.index ["to_loan_id", "link_type"], name: "index_loan_links_on_to_loan_id_and_link_type"
    t.index ["to_loan_id"], name: "index_loan_links_on_to_loan_id"
  end

  create_table "loan_payments", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "loan_id", null: false
    t.string "reference_number", null: false
    t.decimal "amount_cents", null: false
    t.string "amount_currency", default: "PHP"
    t.decimal "principal_cents", default: "0.0", null: false
    t.string "principal_currency", default: "PHP"
    t.decimal "interest_cents", default: "0.0", null: false
    t.string "interest_currency", default: "PHP"
    t.decimal "penalty_cents", default: "0.0", null: false
    t.string "penalty_currency", default: "PHP"
    t.date "payment_date", null: false
    t.bigint "entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_payments_on_cooperative_id"
    t.index ["entry_id"], name: "index_loan_payments_on_entry_id"
    t.index ["loan_id"], name: "index_loan_payments_on_loan_id"
    t.index ["reference_number"], name: "index_loan_payments_on_reference_number", unique: true
  end

  create_table "loan_products", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "interest_rate", null: false
    t.string "interest_calculation", default: "straight_line", null: false
    t.integer "max_term_months", default: 12, null: false
    t.boolean "requires_collateral", default: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_products_on_cooperative_id"
  end

  create_table "loan_repayment_schedules", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "loan_application_id", null: false
    t.integer "sequence", null: false
    t.date "due_date", null: false
    t.decimal "principal_cents", null: false
    t.string "principal_currency", default: "PHP"
    t.decimal "interest_cents", null: false
    t.string "interest_currency", default: "PHP"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_loan_repayment_schedules_on_cooperative_id"
    t.index ["loan_application_id", "sequence"], name: "idx_on_loan_application_id_sequence_2316d64776", unique: true
    t.index ["loan_application_id"], name: "index_loan_repayment_schedules_on_loan_application_id"
  end

  create_table "loan_restructure_cases", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.bigint "new_loan_id"
    t.string "restructure_type", null: false
    t.string "status", default: "draft", null: false
    t.jsonb "proposed_changes", default: {}, null: false
    t.jsonb "simulation_data", default: {}
    t.decimal "arrears_cents", precision: 20, scale: 2, default: "0.0", null: false
    t.string "arrears_currency", default: "PHP", null: false
    t.text "notes"
    t.bigint "requested_by_id"
    t.bigint "approved_by_id"
    t.datetime "submitted_at"
    t.datetime "reviewed_at"
    t.datetime "executed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cooperative_id"
    t.index ["approved_by_id"], name: "index_loan_restructure_cases_on_approved_by_id"
    t.index ["cooperative_id"], name: "index_loan_restructure_cases_on_cooperative_id"
    t.index ["loan_id", "restructure_type"], name: "index_loan_restructure_cases_on_loan_id_and_restructure_type"
    t.index ["loan_id", "status"], name: "index_loan_restructure_cases_on_loan_id_and_status"
    t.index ["loan_id"], name: "index_loan_restructure_cases_on_loan_id"
    t.index ["new_loan_id"], name: "index_loan_restructure_cases_on_new_loan_id"
    t.index ["requested_by_id"], name: "index_loan_restructure_cases_on_requested_by_id"
  end

  create_table "loan_schedules", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.integer "version", default: 1, null: false
    t.string "status", default: "active", null: false
    t.jsonb "schedule_data", default: [], null: false
    t.datetime "superseded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cooperative_id"
    t.index ["cooperative_id"], name: "index_loan_schedules_on_cooperative_id"
    t.index ["loan_id", "status"], name: "index_loan_schedules_on_loan_id_and_status"
    t.index ["loan_id", "version"], name: "index_loan_schedules_on_loan_id_and_version", unique: true
    t.index ["loan_id"], name: "index_loan_schedules_on_loan_id"
  end

  create_table "loans", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "loan_application_id", null: false
    t.bigint "member_id", null: false
    t.bigint "loan_product_id", null: false
    t.decimal "principal_cents", null: false
    t.string "principal_currency", default: "PHP"
    t.decimal "interest_rate", null: false
    t.string "interest_calculation", null: false
    t.integer "term_months", null: false
    t.decimal "outstanding_principal_cents", null: false
    t.string "outstanding_principal_currency", default: "PHP"
    t.string "status", default: "active", null: false
    t.date "disbursed_at"
    t.string "reference_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "restructures_count", default: 0, null: false
    t.integer "max_restructures", default: 2, null: false
    t.index ["cooperative_id"], name: "index_loans_on_cooperative_id"
    t.index ["loan_application_id"], name: "index_loans_on_loan_application_id"
    t.index ["loan_product_id"], name: "index_loans_on_loan_product_id"
    t.index ["member_id"], name: "index_loans_on_member_id"
    t.index ["reference_number"], name: "index_loans_on_reference_number", unique: true
  end

  create_table "management_alert_subscriptions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "user_id", null: false
    t.string "alert_type", null: false
    t.string "channel", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_alert_subscriptions_on_cooperative_id"
    t.index ["user_id", "alert_type", "channel"], name: "idx_on_user_id_alert_type_channel_8c88c19464", unique: true
    t.index ["user_id"], name: "index_management_alert_subscriptions_on_user_id"
  end

  create_table "management_alerts", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "alert_type", null: false
    t.string "severity", default: "info", null: false
    t.string "title", null: false
    t.text "message"
    t.string "source"
    t.string "status", default: "active", null: false
    t.string "triggered_by_type"
    t.integer "triggered_by_id"
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_type"], name: "index_management_alerts_on_alert_type"
    t.index ["cooperative_id"], name: "index_management_alerts_on_cooperative_id"
    t.index ["resolved_by_id"], name: "index_management_alerts_on_resolved_by_id"
    t.index ["status"], name: "index_management_alerts_on_status"
  end

  create_table "management_approval_requests", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "requestable_type", null: false
    t.integer "requestable_id", null: false
    t.bigint "workflow_id"
    t.string "status", default: "pending", null: false
    t.bigint "requested_by_id", null: false
    t.integer "current_step", default: 1, null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_approval_requests_on_cooperative_id"
    t.index ["requested_by_id"], name: "index_management_approval_requests_on_requested_by_id"
    t.index ["status"], name: "index_management_approval_requests_on_status"
    t.index ["workflow_id"], name: "index_management_approval_requests_on_workflow_id"
  end

  create_table "management_approval_workflow_steps", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "approval_workflow_id", null: false
    t.integer "sequence", null: false
    t.bigint "approver_role_id"
    t.bigint "approver_user_id"
    t.integer "threshold_cents_min"
    t.integer "threshold_cents_max"
    t.string "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approval_workflow_id", "sequence"], name: "idx_on_approval_workflow_id_sequence_340a85b293", unique: true
    t.index ["approval_workflow_id"], name: "idx_on_approval_workflow_id_a1ea19780b"
    t.index ["approver_role_id"], name: "index_management_approval_workflow_steps_on_approver_role_id"
    t.index ["approver_user_id"], name: "index_management_approval_workflow_steps_on_approver_user_id"
    t.index ["cooperative_id"], name: "index_management_approval_workflow_steps_on_cooperative_id"
  end

  create_table "management_approval_workflows", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.string "description"
    t.string "applicable_entity_type"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_approval_workflows_on_cooperative_id"
  end

  create_table "management_approvals", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "approval_request_id", null: false
    t.bigint "step_id", null: false
    t.bigint "approver_id", null: false
    t.string "status", null: false
    t.text "comment"
    t.datetime "signed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approval_request_id"], name: "index_management_approvals_on_approval_request_id"
    t.index ["approver_id"], name: "index_management_approvals_on_approver_id"
    t.index ["cooperative_id"], name: "index_management_approvals_on_cooperative_id"
    t.index ["step_id"], name: "index_management_approvals_on_step_id"
  end

  create_table "management_audit_logs", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "auditable_type"
    t.integer "auditable_id"
    t.string "action", null: false
    t.integer "actor_id"
    t.string "actor_role"
    t.bigint "branch_id"
    t.string "ip_address"
    t.text "user_agent"
    t.jsonb "before_state"
    t.jsonb "after_state"
    t.jsonb "approval_chain"
    t.string "config_version"
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_management_audit_logs_on_action"
    t.index ["branch_id"], name: "index_management_audit_logs_on_branch_id"
    t.index ["cooperative_id"], name: "index_management_audit_logs_on_cooperative_id"
    t.index ["created_at"], name: "index_management_audit_logs_on_created_at"
  end

  create_table "management_branch_performance_snapshots", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "branch_id", null: false
    t.date "snapshot_date", null: false
    t.jsonb "metrics", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id", "snapshot_date"], name: "idx_on_branch_id_snapshot_date_c28cd56a00", unique: true
    t.index ["branch_id"], name: "index_management_branch_performance_snapshots_on_branch_id"
    t.index ["cooperative_id"], name: "idx_on_cooperative_id_5cfce3d3e1"
  end

  create_table "management_branches", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.text "address"
    t.string "contact_number"
    t.string "phone"
    t.string "email"
    t.string "status", default: "active", null: false
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.integer "depth", default: 0
    t.integer "children_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id", "code"], name: "index_management_branches_on_cooperative_id_and_code", unique: true
    t.index ["cooperative_id"], name: "index_management_branches_on_cooperative_id"
  end

  create_table "management_configuration_versions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "configuration_id", null: false
    t.integer "version", null: false
    t.jsonb "value", default: {}, null: false
    t.bigint "changed_by_id"
    t.text "change_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["changed_by_id"], name: "index_management_configuration_versions_on_changed_by_id"
    t.index ["configuration_id", "version"], name: "idx_on_configuration_id_version_a1261d1f20", unique: true
    t.index ["configuration_id"], name: "index_management_configuration_versions_on_configuration_id"
    t.index ["cooperative_id"], name: "index_management_configuration_versions_on_cooperative_id"
  end

  create_table "management_configurations", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "key", null: false
    t.jsonb "value", default: {}, null: false
    t.integer "version", default: 1, null: false
    t.string "status", default: "draft", null: false
    t.string "configurable_type"
    t.integer "configurable_id"
    t.bigint "changed_by_id"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_management_configurations_on_approved_by_id"
    t.index ["changed_by_id"], name: "index_management_configurations_on_changed_by_id"
    t.index ["cooperative_id"], name: "index_management_configurations_on_cooperative_id"
    t.index ["key", "configurable_type", "configurable_id"], name: "idx_on_key_configurable_type_configurable_id_f945d90a9e", unique: true
  end

  create_table "management_departments", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "branch_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id", "code"], name: "index_management_departments_on_branch_id_and_code", unique: true
    t.index ["branch_id"], name: "index_management_departments_on_branch_id"
    t.index ["cooperative_id"], name: "index_management_departments_on_cooperative_id"
  end

  create_table "management_permissions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "action", null: false
    t.string "subject", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id", "action", "subject"], name: "index_management_permissions_on_cooperative_id_action_subject", unique: true
    t.index ["cooperative_id"], name: "index_management_permissions_on_cooperative_id"
  end

  create_table "management_policies", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.string "category", null: false
    t.string "scope"
    t.string "status", default: "active", null: false
    t.integer "version", default: 1, null: false
    t.jsonb "config", default: {}
    t.string "target_entity_type"
    t.integer "target_entity_id"
    t.bigint "created_by_id"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_management_policies_on_approved_by_id"
    t.index ["cooperative_id", "code"], name: "index_management_policies_on_cooperative_id_and_code", unique: true
    t.index ["cooperative_id"], name: "index_management_policies_on_cooperative_id"
    t.index ["created_by_id"], name: "index_management_policies_on_created_by_id"
  end

  create_table "management_policy_rules", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "policy_id", null: false
    t.string "field", null: false
    t.string "operator", null: false
    t.string "value", null: false
    t.string "effect", default: "deny", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_policy_rules_on_cooperative_id"
    t.index ["policy_id"], name: "index_management_policy_rules_on_policy_id"
  end

  create_table "management_risk_indicators", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "branch_id"
    t.string "indicator_type", null: false
    t.decimal "value"
    t.decimal "threshold"
    t.string "status", default: "normal", null: false
    t.date "as_of_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id", "indicator_type", "as_of_date"], name: "idx_on_branch_id_indicator_type_as_of_date_48924e88f2", unique: true
    t.index ["branch_id"], name: "index_management_risk_indicators_on_branch_id"
    t.index ["cooperative_id"], name: "index_management_risk_indicators_on_cooperative_id"
  end

  create_table "management_role_assignments", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.bigint "branch_id"
    t.bigint "department_id"
    t.date "active_from", null: false
    t.date "active_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_management_role_assignments_on_branch_id"
    t.index ["cooperative_id"], name: "index_management_role_assignments_on_cooperative_id"
    t.index ["department_id"], name: "index_management_role_assignments_on_department_id"
    t.index ["role_id"], name: "index_management_role_assignments_on_role_id"
    t.index ["user_id"], name: "index_management_role_assignments_on_user_id"
  end

  create_table "management_role_permissions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "role_id", null: false
    t.bigint "permission_id", null: false
    t.jsonb "constraints", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_role_permissions_on_cooperative_id"
    t.index ["permission_id"], name: "index_management_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_management_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_management_role_permissions_on_role_id"
  end

  create_table "management_roles", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.integer "rank", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id", "code"], name: "index_management_roles_on_cooperative_id_and_code", unique: true
    t.index ["cooperative_id"], name: "index_management_roles_on_cooperative_id"
  end

  create_table "management_system_health_snapshots", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "metric_name", null: false
    t.decimal "value"
    t.string "unit"
    t.string "status", default: "healthy", null: false
    t.datetime "captured_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_system_health_snapshots_on_cooperative_id"
    t.index ["metric_name", "captured_at"], name: "idx_on_metric_name_captured_at_597dc63458"
  end

  create_table "management_teams", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "department_id", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_management_teams_on_cooperative_id"
    t.index ["department_id"], name: "index_management_teams_on_department_id"
  end

  create_table "member_addresses", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id", null: false
    t.string "house_street", null: false
    t.string "barangay", null: false
    t.string "city", null: false
    t.string "province", null: false
    t.string "region", null: false
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_member_addresses_on_cooperative_id"
    t.index ["member_id"], name: "index_member_addresses_on_member_id"
  end

  create_table "member_identifications", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id", null: false
    t.string "id_type", null: false
    t.string "id_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_member_identifications_on_cooperative_id"
    t.index ["id_type", "id_number"], name: "index_member_identifications_on_id_type_and_id_number", unique: true
    t.index ["member_id"], name: "index_member_identifications_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.string "suffix"
    t.date "birth_date", null: false
    t.string "gender", null: false
    t.string "civil_status", null: false
    t.string "mobile_number", null: false
    t.string "email_address"
    t.string "member_identifier"
    t.string "password_digest"
    t.string "otp_secret"
    t.boolean "otp_enabled", default: false, null: false
    t.datetime "otp_verified_at"
    t.datetime "last_login_at"
    t.string "portal_status", default: "inactive", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_members_on_cooperative_id"
    t.index ["email_address"], name: "index_members_on_email_address", unique: true
    t.index ["member_identifier"], name: "index_members_on_member_identifier", unique: true
  end

  create_table "membership_applications", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "uuid", null: false
    t.string "status", default: "draft", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "suffix"
    t.date "birth_date"
    t.string "gender"
    t.string "civil_status"
    t.string "mobile_number"
    t.string "email_address"
    t.string "house_street"
    t.string "barangay"
    t.string "city"
    t.string "province"
    t.string "region"
    t.string "zip_code"
    t.jsonb "identifications", default: []
    t.jsonb "signature_specimens", default: [], null: false
    t.integer "current_step", default: 0, null: false
    t.jsonb "profile_images", default: [], null: false
    t.jsonb "sources_of_income", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_membership_applications_on_cooperative_id"
    t.index ["uuid"], name: "index_membership_applications_on_uuid", unique: true
  end

  create_table "messaging_channels", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_messaging_channels_on_cooperative_id"
    t.index ["name"], name: "index_messaging_channels_on_name", unique: true
  end

  create_table "messaging_message_deliveries", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "message_id", null: false
    t.bigint "channel_id", null: false
    t.bigint "provider_id"
    t.string "status", default: "queued", null: false
    t.integer "attempts_count", default: 0
    t.text "last_error"
    t.string "provider_message_id"
    t.datetime "sent_at"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_messaging_message_deliveries_on_channel_id"
    t.index ["cooperative_id"], name: "index_messaging_message_deliveries_on_cooperative_id"
    t.index ["message_id"], name: "index_messaging_message_deliveries_on_message_id"
    t.index ["provider_id"], name: "index_messaging_message_deliveries_on_provider_id"
    t.index ["status"], name: "index_messaging_message_deliveries_on_status"
  end

  create_table "messaging_messages", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "message_type", null: false
    t.string "recipient_type", null: false
    t.integer "recipient_id", null: false
    t.jsonb "payload", default: {}
    t.string "status", default: "pending", null: false
    t.datetime "scheduled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_messaging_messages_on_cooperative_id"
    t.index ["message_type"], name: "index_messaging_messages_on_message_type"
    t.index ["recipient_type", "recipient_id"], name: "index_messaging_messages_on_recipient_type_and_recipient_id"
    t.index ["status"], name: "index_messaging_messages_on_status"
  end

  create_table "messaging_provider_webhooks", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "provider_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_messaging_provider_webhooks_on_cooperative_id"
    t.index ["provider_id", "event_type"], name: "idx_on_provider_id_event_type_114a5f5c88", unique: true
    t.index ["provider_id"], name: "index_messaging_provider_webhooks_on_provider_id"
  end

  create_table "messaging_providers", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "channel_id", null: false
    t.string "name", null: false
    t.jsonb "config", default: {}
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id", "name"], name: "index_messaging_providers_on_channel_id_and_name", unique: true
    t.index ["channel_id"], name: "index_messaging_providers_on_channel_id"
    t.index ["cooperative_id"], name: "index_messaging_providers_on_cooperative_id"
  end

  create_table "mfa_attempt_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.boolean "success", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.string "device_fingerprint"
    t.string "failure_reason"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_mfa_attempt_logs_on_action"
    t.index ["created_at"], name: "index_mfa_attempt_logs_on_created_at"
    t.index ["user_id", "created_at"], name: "index_mfa_attempt_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_mfa_attempt_logs_on_user_id"
  end

  create_table "portal_announcements", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "status", default: "draft", null: false
    t.datetime "published_at"
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_portal_announcements_on_author_id"
    t.index ["cooperative_id"], name: "index_portal_announcements_on_cooperative_id"
    t.index ["published_at"], name: "index_portal_announcements_on_published_at"
    t.index ["status"], name: "index_portal_announcements_on_status"
  end

  create_table "portal_enrollment_tokens", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_portal_enrollment_tokens_on_cooperative_id"
    t.index ["member_id"], name: "index_portal_enrollment_tokens_on_member_id"
    t.index ["token"], name: "index_portal_enrollment_tokens_on_token", unique: true
  end

  create_table "portal_sessions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id", null: false
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "revoked_at"
    t.datetime "last_activity_at"
    t.datetime "mfa_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_portal_sessions_on_cooperative_id"
    t.index ["last_activity_at"], name: "index_portal_sessions_on_last_activity_at"
    t.index ["member_id", "revoked_at"], name: "index_portal_sessions_on_member_id_and_revoked_at"
    t.index ["member_id"], name: "index_portal_sessions_on_member_id"
    t.index ["revoked_at"], name: "index_portal_sessions_on_revoked_at"
  end

  create_table "running_balances", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "account_id"
    t.bigint "ledger_id", null: false
    t.date "as_of_date", null: false
    t.integer "balance_cents", null: false
    t.string "balance_currency", limit: 3, default: "PHP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "as_of_date"], name: "idx_running_balances_on_account_date", unique: true, where: "(account_id IS NOT NULL)"
    t.index ["account_id"], name: "index_running_balances_on_account_id"
    t.index ["cooperative_id"], name: "index_running_balances_on_cooperative_id"
    t.index ["ledger_id", "as_of_date"], name: "idx_running_balances_on_ledger_date", unique: true, where: "(account_id IS NULL)"
    t.index ["ledger_id"], name: "index_running_balances_on_ledger_id"
  end

  create_table "saved_filters", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.jsonb "filters", default: {}, null: false
    t.string "filter_type", default: "journal_entry", null: false
    t.boolean "is_shared", default: false, null: false
    t.bigint "cooperative_id"
    t.string "role_restriction"
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_saved_filters_on_cooperative_id"
    t.index ["filter_type"], name: "index_saved_filters_on_filter_type"
    t.index ["is_default"], name: "index_saved_filters_on_is_default"
    t.index ["is_shared"], name: "index_saved_filters_on_is_shared"
    t.index ["name"], name: "index_saved_filters_on_name"
    t.index ["user_id"], name: "index_saved_filters_on_user_id"
  end

  create_table "security_password_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_security_password_histories_on_created_at"
    t.index ["user_id"], name: "index_security_password_histories_on_user_id"
  end

  create_table "security_password_policies", force: :cascade do |t|
    t.string "name"
    t.integer "min_length"
    t.boolean "require_uppercase"
    t.boolean "require_lowercase"
    t.boolean "require_digits"
    t.boolean "require_symbols"
    t.integer "max_failed_attempts"
    t.integer "lockout_duration"
    t.integer "password_expiry_days"
    t.integer "password_history_count"
    t.bigint "cooperative_id", null: false
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_security_password_policies_on_cooperative_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "revoked_at"
    t.datetime "last_activity_at"
    t.datetime "mfa_verified_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "treasury_cash_sessions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "user_id", null: false
    t.bigint "cash_account_id", null: false
    t.date "date", null: false
    t.string "status", default: "open", null: false
    t.datetime "opened_at", null: false
    t.datetime "closed_at"
    t.decimal "beginning_balance_cents"
    t.decimal "ending_balance_cents"
    t.text "notes"
    t.jsonb "counts", default: "[]"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_treasury_cash_sessions_on_cash_account_id"
    t.index ["cooperative_id"], name: "index_treasury_cash_sessions_on_cooperative_id"
    t.index ["user_id", "cash_account_id", "date"], name: "idx_on_user_id_cash_account_id_date_98598fc1bb", unique: true
    t.index ["user_id"], name: "index_treasury_cash_sessions_on_user_id"
  end

  create_table "treasury_savings_accounts", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "savings_product_id", null: false
    t.string "depositor_type", null: false
    t.integer "depositor_id", null: false
    t.integer "account_type", default: 0, null: false
    t.string "status", default: "active", null: false
    t.string "account_number", null: false
    t.datetime "opened_at"
    t.datetime "closed_at"
    t.bigint "liability_account_id"
    t.bigint "interest_expense_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id", "account_number"], name: "idx_treasury_savings_accounts_on_coop_account_number", unique: true
    t.index ["cooperative_id"], name: "index_treasury_savings_accounts_on_cooperative_id"
    t.index ["depositor_type", "depositor_id"], name: "idx_on_depositor_type_depositor_id_b642e154d8"
    t.index ["interest_expense_account_id"], name: "index_treasury_savings_accounts_on_interest_expense_account_id"
    t.index ["liability_account_id"], name: "index_treasury_savings_accounts_on_liability_account_id"
    t.index ["savings_product_id"], name: "index_treasury_savings_accounts_on_savings_product_id"
  end

  create_table "treasury_savings_product_interest_rates", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "savings_product_id", null: false
    t.decimal "rate", null: false
    t.boolean "current", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "idx_on_cooperative_id_d0876bcbb5"
    t.index ["savings_product_id"], name: "idx_on_savings_product_id_06a7ca0e75"
  end

  create_table "treasury_savings_products", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.bigint "liability_ledger_id"
    t.bigint "interest_expense_ledger_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_treasury_savings_products_on_cooperative_id"
    t.index ["interest_expense_ledger_id"], name: "index_treasury_savings_products_on_interest_expense_ledger_id"
    t.index ["liability_ledger_id"], name: "index_treasury_savings_products_on_liability_ledger_id"
  end

  create_table "treasury_savings_transactions", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "savings_account_id", null: false
    t.integer "transaction_type", null: false
    t.decimal "amount_cents", null: false
    t.string "amount_currency", default: "PHP", null: false
    t.bigint "cash_account_id", null: false
    t.bigint "entry_id"
    t.string "reference_number", null: false
    t.text "notes"
    t.string "status", default: "completed", null: false
    t.datetime "posted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_treasury_savings_transactions_on_cash_account_id"
    t.index ["cooperative_id"], name: "index_treasury_savings_transactions_on_cooperative_id"
    t.index ["entry_id"], name: "index_treasury_savings_transactions_on_entry_id"
    t.index ["reference_number"], name: "index_treasury_savings_transactions_on_reference_number", unique: true
    t.index ["savings_account_id"], name: "index_treasury_savings_transactions_on_savings_account_id"
  end

  create_table "treasury_time_deposit_products", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "minimum_deposit_cents", default: 0, null: false
    t.string "minimum_deposit_currency", default: "PHP", null: false
    t.decimal "interest_rate", null: false
    t.integer "term_in_days", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_treasury_time_deposit_products_on_cooperative_id"
  end

  create_table "treasury_time_deposits", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "depositor_type", null: false
    t.integer "depositor_id", null: false
    t.bigint "time_deposit_product_id", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "PHP", null: false
    t.decimal "interest_rate", null: false
    t.date "matured_on"
    t.integer "interest_earned_cents", default: 0
    t.string "interest_earned_currency", default: "PHP", null: false
    t.string "status", default: "pending", null: false
    t.datetime "opened_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cooperative_id"], name: "index_treasury_time_deposits_on_cooperative_id"
    t.index ["depositor_type", "depositor_id"], name: "idx_on_depositor_type_depositor_id_95e40b9cf8"
    t.index ["time_deposit_product_id"], name: "index_treasury_time_deposits_on_time_deposit_product_id"
  end

  create_table "treasury_vault_transfers", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "cash_session_id", null: false
    t.string "direction", null: false
    t.decimal "amount_cents", null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.bigint "voucher_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_treasury_vault_transfers_on_approved_by_id"
    t.index ["cash_session_id"], name: "index_treasury_vault_transfers_on_cash_session_id"
    t.index ["cooperative_id"], name: "index_treasury_vault_transfers_on_cooperative_id"
    t.index ["voucher_id"], name: "index_treasury_vault_transfers_on_voucher_id"
  end

  create_table "treasury_vouchers", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.string "type", null: false
    t.bigint "cash_session_id", null: false
    t.string "voucher_number", null: false
    t.string "status", default: "pending", null: false
    t.decimal "amount_cents", null: false
    t.string "amount_currency", default: "PHP", null: false
    t.text "description"
    t.bigint "cash_account_id", null: false
    t.bigint "entry_id"
    t.datetime "posted_at"
    t.string "counterparty_type"
    t.integer "counterparty_id"
    t.string "category", null: false
    t.string "transactable_type"
    t.integer "transactable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_treasury_vouchers_on_cash_account_id"
    t.index ["cash_session_id"], name: "index_treasury_vouchers_on_cash_session_id"
    t.index ["cooperative_id"], name: "index_treasury_vouchers_on_cooperative_id"
    t.index ["counterparty_type", "counterparty_id"], name: "idx_on_counterparty_type_counterparty_id_e5b6172d0a"
    t.index ["entry_id"], name: "index_treasury_vouchers_on_entry_id"
    t.index ["status"], name: "index_treasury_vouchers_on_status"
    t.index ["transactable_type", "transactable_id"], name: "idx_on_transactable_type_transactable_id_bb0ab59b28"
    t.index ["type"], name: "index_treasury_vouchers_on_type"
    t.index ["voucher_number"], name: "index_treasury_vouchers_on_voucher_number", unique: true
  end

  create_table "trusted_devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "device_fingerprint_hash", null: false
    t.datetime "last_used_at", null: false
    t.datetime "expires_at", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_trusted_devices_on_expires_at"
    t.index ["user_id", "device_fingerprint_hash"], name: "index_trusted_devices_on_user_id_and_device_fingerprint_hash", unique: true
    t.index ["user_id"], name: "index_trusted_devices_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.string "otp_secret"
    t.boolean "otp_enabled", default: false, null: false
    t.datetime "otp_verified_at"
    t.string "employee_id"
    t.string "full_name"
    t.string "status"
    t.jsonb "permission_overrides"
    t.bigint "cooperative_id", null: false
    t.integer "failed_attempts"
    t.datetime "locked_at"
    t.datetime "password_changed_at"
    t.boolean "force_password_change"
    t.string "last_login_ip"
    t.datetime "last_seen_at"
    t.string "last_device"
    t.integer "session_version"
    t.index ["cooperative_id"], name: "index_users_on_cooperative_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["employee_id"], name: "index_users_on_employee_id", unique: true
  end

  add_foreign_key "accounting_cash_accounts", "accounts"
  add_foreign_key "accounting_cash_accounts", "cooperatives"
  add_foreign_key "accounts", "cooperatives"
  add_foreign_key "accounts", "ledgers"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "amount_lines", "accounts"
  add_foreign_key "amount_lines", "cooperatives"
  add_foreign_key "amount_lines", "entries"
  add_foreign_key "backup_codes", "users"
  add_foreign_key "compliance_controls", "cooperatives"
  add_foreign_key "compliance_evidences", "compliance_controls", column: "control_id"
  add_foreign_key "compliance_evidences", "cooperatives"
  add_foreign_key "entries", "cooperatives"
  add_foreign_key "entry_template_lines", "cooperatives"
  add_foreign_key "entry_template_lines", "entry_templates"
  add_foreign_key "entry_templates", "cooperatives"
  add_foreign_key "equity_accounts", "cooperatives"
  add_foreign_key "equity_accounts", "equity_products", column: "share_product_id"
  add_foreign_key "equity_accounts", "members"
  add_foreign_key "equity_accounts", "users", column: "opened_by_id"
  add_foreign_key "equity_products", "cooperatives"
  add_foreign_key "equity_products", "ledgers", column: "equity_ledger_id"
  add_foreign_key "equity_transactions", "accounts", column: "cash_account_id"
  add_foreign_key "equity_transactions", "cooperatives"
  add_foreign_key "equity_transactions", "entries"
  add_foreign_key "equity_transactions", "equity_accounts", column: "share_capital_account_id"
  add_foreign_key "equity_transactions", "users", column: "posted_by_id"
  add_foreign_key "external_bank_accounts", "accounts", column: "cash_on_hand_account_id"
  add_foreign_key "external_bank_accounts", "accounts", column: "interest_income_account_id"
  add_foreign_key "external_bank_accounts", "cooperatives"
  add_foreign_key "external_bank_accounts", "external_banks"
  add_foreign_key "external_bank_documents", "cooperatives"
  add_foreign_key "external_bank_documents", "external_bank_accounts"
  add_foreign_key "external_bank_transaction_allocations", "cooperatives"
  add_foreign_key "external_bank_transaction_allocations", "entries", column: "journal_entry_id"
  add_foreign_key "external_bank_transaction_allocations", "external_bank_transactions"
  add_foreign_key "external_bank_transaction_allocations", "users", column: "created_by_id"
  add_foreign_key "external_bank_transactions", "cooperatives"
  add_foreign_key "external_bank_transactions", "external_bank_accounts"
  add_foreign_key "external_bank_transactions", "external_bank_documents"
  add_foreign_key "external_banks", "accounts", column: "cash_on_hand_account_id"
  add_foreign_key "external_banks", "cooperatives"
  add_foreign_key "external_banks", "ledgers", column: "cash_on_hand_ledger_id"
  add_foreign_key "external_banks", "ledgers", column: "interest_income_ledger_id"
  add_foreign_key "fraud_incidents", "cooperatives"
  add_foreign_key "fraud_incidents", "fraud_rules", column: "rule_id"
  add_foreign_key "fraud_rules", "cooperatives"
  add_foreign_key "ledgers", "cooperatives"
  add_foreign_key "loan_applications", "cooperatives"
  add_foreign_key "loan_applications", "loan_products"
  add_foreign_key "loan_applications", "members"
  add_foreign_key "loan_charges", "cooperatives"
  add_foreign_key "loan_charges", "loan_products"
  add_foreign_key "loan_co_makers", "cooperatives"
  add_foreign_key "loan_co_makers", "loan_applications"
  add_foreign_key "loan_co_makers", "members"
  add_foreign_key "loan_collaterals", "cooperatives"
  add_foreign_key "loan_collaterals", "loan_applications"
  add_foreign_key "loan_events", "cooperatives"
  add_foreign_key "loan_events", "loans"
  add_foreign_key "loan_links", "cooperatives"
  add_foreign_key "loan_links", "loans", column: "from_loan_id"
  add_foreign_key "loan_links", "loans", column: "to_loan_id"
  add_foreign_key "loan_payments", "cooperatives"
  add_foreign_key "loan_payments", "entries"
  add_foreign_key "loan_payments", "loans"
  add_foreign_key "loan_products", "cooperatives"
  add_foreign_key "loan_repayment_schedules", "cooperatives"
  add_foreign_key "loan_repayment_schedules", "loan_applications"
  add_foreign_key "loan_restructure_cases", "cooperatives"
  add_foreign_key "loan_restructure_cases", "loans"
  add_foreign_key "loan_restructure_cases", "loans", column: "new_loan_id"
  add_foreign_key "loan_restructure_cases", "users", column: "approved_by_id"
  add_foreign_key "loan_restructure_cases", "users", column: "requested_by_id"
  add_foreign_key "loan_schedules", "cooperatives"
  add_foreign_key "loan_schedules", "loans"
  add_foreign_key "loans", "cooperatives"
  add_foreign_key "loans", "loan_applications"
  add_foreign_key "loans", "loan_products"
  add_foreign_key "loans", "members"
  add_foreign_key "management_alert_subscriptions", "cooperatives"
  add_foreign_key "management_alert_subscriptions", "users"
  add_foreign_key "management_alerts", "cooperatives"
  add_foreign_key "management_alerts", "users", column: "resolved_by_id"
  add_foreign_key "management_approval_requests", "cooperatives"
  add_foreign_key "management_approval_requests", "management_approval_workflows", column: "workflow_id"
  add_foreign_key "management_approval_requests", "users", column: "requested_by_id"
  add_foreign_key "management_approval_workflow_steps", "cooperatives"
  add_foreign_key "management_approval_workflow_steps", "management_approval_workflows", column: "approval_workflow_id"
  add_foreign_key "management_approval_workflow_steps", "management_roles", column: "approver_role_id"
  add_foreign_key "management_approval_workflow_steps", "users", column: "approver_user_id"
  add_foreign_key "management_approval_workflows", "cooperatives"
  add_foreign_key "management_approvals", "cooperatives"
  add_foreign_key "management_approvals", "management_approval_requests", column: "approval_request_id"
  add_foreign_key "management_approvals", "management_approval_workflow_steps", column: "step_id"
  add_foreign_key "management_approvals", "users", column: "approver_id"
  add_foreign_key "management_audit_logs", "cooperatives"
  add_foreign_key "management_audit_logs", "management_branches", column: "branch_id"
  add_foreign_key "management_branch_performance_snapshots", "cooperatives"
  add_foreign_key "management_branch_performance_snapshots", "management_branches", column: "branch_id"
  add_foreign_key "management_branches", "cooperatives"
  add_foreign_key "management_configuration_versions", "cooperatives"
  add_foreign_key "management_configuration_versions", "management_configurations", column: "configuration_id"
  add_foreign_key "management_configuration_versions", "users", column: "changed_by_id"
  add_foreign_key "management_configurations", "cooperatives"
  add_foreign_key "management_configurations", "users", column: "approved_by_id"
  add_foreign_key "management_configurations", "users", column: "changed_by_id"
  add_foreign_key "management_departments", "cooperatives"
  add_foreign_key "management_departments", "management_branches", column: "branch_id"
  add_foreign_key "management_permissions", "cooperatives"
  add_foreign_key "management_policies", "cooperatives"
  add_foreign_key "management_policies", "users", column: "approved_by_id"
  add_foreign_key "management_policies", "users", column: "created_by_id"
  add_foreign_key "management_policy_rules", "cooperatives"
  add_foreign_key "management_policy_rules", "management_policies", column: "policy_id"
  add_foreign_key "management_risk_indicators", "cooperatives"
  add_foreign_key "management_risk_indicators", "management_branches", column: "branch_id"
  add_foreign_key "management_role_assignments", "cooperatives"
  add_foreign_key "management_role_assignments", "management_branches", column: "branch_id"
  add_foreign_key "management_role_assignments", "management_departments", column: "department_id"
  add_foreign_key "management_role_assignments", "management_roles", column: "role_id"
  add_foreign_key "management_role_assignments", "users"
  add_foreign_key "management_role_permissions", "cooperatives"
  add_foreign_key "management_role_permissions", "management_permissions", column: "permission_id"
  add_foreign_key "management_role_permissions", "management_roles", column: "role_id"
  add_foreign_key "management_roles", "cooperatives"
  add_foreign_key "management_system_health_snapshots", "cooperatives"
  add_foreign_key "management_teams", "cooperatives"
  add_foreign_key "management_teams", "management_departments", column: "department_id"
  add_foreign_key "member_addresses", "cooperatives"
  add_foreign_key "member_addresses", "members"
  add_foreign_key "member_identifications", "cooperatives"
  add_foreign_key "member_identifications", "members"
  add_foreign_key "members", "cooperatives"
  add_foreign_key "membership_applications", "cooperatives"
  add_foreign_key "messaging_channels", "cooperatives"
  add_foreign_key "messaging_message_deliveries", "cooperatives"
  add_foreign_key "messaging_message_deliveries", "messaging_channels", column: "channel_id"
  add_foreign_key "messaging_message_deliveries", "messaging_messages", column: "message_id"
  add_foreign_key "messaging_message_deliveries", "messaging_providers", column: "provider_id"
  add_foreign_key "messaging_messages", "cooperatives"
  add_foreign_key "messaging_provider_webhooks", "cooperatives"
  add_foreign_key "messaging_provider_webhooks", "messaging_providers", column: "provider_id"
  add_foreign_key "messaging_providers", "cooperatives"
  add_foreign_key "messaging_providers", "messaging_channels", column: "channel_id"
  add_foreign_key "mfa_attempt_logs", "users"
  add_foreign_key "portal_announcements", "cooperatives"
  add_foreign_key "portal_announcements", "users", column: "author_id"
  add_foreign_key "portal_enrollment_tokens", "cooperatives"
  add_foreign_key "portal_enrollment_tokens", "members"
  add_foreign_key "portal_sessions", "cooperatives"
  add_foreign_key "portal_sessions", "members"
  add_foreign_key "running_balances", "accounts"
  add_foreign_key "running_balances", "cooperatives"
  add_foreign_key "running_balances", "ledgers"
  add_foreign_key "saved_filters", "cooperatives"
  add_foreign_key "saved_filters", "users"
  add_foreign_key "security_password_histories", "users"
  add_foreign_key "security_password_policies", "cooperatives"
  add_foreign_key "sessions", "users"
  add_foreign_key "treasury_cash_sessions", "accounts", column: "cash_account_id"
  add_foreign_key "treasury_cash_sessions", "cooperatives"
  add_foreign_key "treasury_cash_sessions", "users"
  add_foreign_key "treasury_savings_accounts", "accounts", column: "interest_expense_account_id"
  add_foreign_key "treasury_savings_accounts", "accounts", column: "liability_account_id"
  add_foreign_key "treasury_savings_accounts", "cooperatives"
  add_foreign_key "treasury_savings_accounts", "treasury_savings_products", column: "savings_product_id"
  add_foreign_key "treasury_savings_product_interest_rates", "cooperatives"
  add_foreign_key "treasury_savings_product_interest_rates", "treasury_savings_products", column: "savings_product_id"
  add_foreign_key "treasury_savings_products", "cooperatives"
  add_foreign_key "treasury_savings_products", "ledgers", column: "interest_expense_ledger_id"
  add_foreign_key "treasury_savings_products", "ledgers", column: "liability_ledger_id"
  add_foreign_key "treasury_savings_transactions", "accounts", column: "cash_account_id"
  add_foreign_key "treasury_savings_transactions", "cooperatives"
  add_foreign_key "treasury_savings_transactions", "entries"
  add_foreign_key "treasury_savings_transactions", "treasury_savings_accounts", column: "savings_account_id"
  add_foreign_key "treasury_time_deposit_products", "cooperatives"
  add_foreign_key "treasury_time_deposits", "cooperatives"
  add_foreign_key "treasury_time_deposits", "treasury_time_deposit_products", column: "time_deposit_product_id"
  add_foreign_key "treasury_vault_transfers", "cooperatives"
  add_foreign_key "treasury_vault_transfers", "treasury_cash_sessions", column: "cash_session_id"
  add_foreign_key "treasury_vault_transfers", "treasury_vouchers", column: "voucher_id"
  add_foreign_key "treasury_vault_transfers", "users", column: "approved_by_id"
  add_foreign_key "treasury_vouchers", "accounts", column: "cash_account_id"
  add_foreign_key "treasury_vouchers", "cooperatives"
  add_foreign_key "treasury_vouchers", "entries"
  add_foreign_key "treasury_vouchers", "treasury_cash_sessions", column: "cash_session_id"
  add_foreign_key "trusted_devices", "users"
  add_foreign_key "users", "cooperatives"
end
