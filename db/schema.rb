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

ActiveRecord::Schema[8.0].define(version: 2026_06_18_073000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "account_type", ["asset", "equity", "liability", "revenue", "expense"]

  create_table "accounting_cash_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_accounting_cash_accounts_on_account_id"
    t.index ["user_id", "account_id"], name: "index_accounting_cash_accounts_on_user_id_and_account_id", unique: true
    t.index ["user_id"], name: "index_accounting_cash_accounts_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.bigint "ledger_id", null: false
    t.string "name", null: false
    t.string "account_code", null: false
    t.boolean "contra", default: false
    t.enum "account_type", null: false, enum_type: "account_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_code"], name: "index_accounts_on_account_code", unique: true
    t.index ["ledger_id"], name: "index_accounts_on_ledger_id"
    t.index ["name", "account_code"], name: "trgm_accounts_idx", opclass: :gin_trgm_ops, using: :gin
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
    t.bigint "entry_id", null: false
    t.bigint "account_id", null: false
    t.integer "amount_type", null: false
    t.integer "amount_cents", null: false
    t.string "amount_currency", limit: 3, default: "PHP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "entry_id"], name: "index_amount_lines_on_account_id_and_entry_id"
    t.index ["account_id"], name: "index_amount_lines_on_account_id"
    t.index ["entry_id"], name: "index_amount_lines_on_entry_id"
  end

  create_table "cooperatives", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.string "contact_number"
    t.string "registration_number"
    t.bigint "vault_account_id"
    t.index ["vault_account_id"], name: "index_cooperatives_on_vault_account_id"
  end

  create_table "entries", force: :cascade do |t|
    t.string "reference_number", null: false
    t.text "description", null: false
    t.datetime "posted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["posted_at"], name: "index_entries_on_posted_at"
    t.index ["reference_number"], name: "index_entries_on_reference_number", unique: true
  end

  create_table "equity_accounts", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.bigint "share_product_id", null: false
    t.string "account_number", null: false
    t.string "status", default: "active", null: false
    t.datetime "opened_at", null: false
    t.integer "opened_by_id", null: false
    t.string "branch"
    t.text "remarks"
    t.bigint "equity_account_id"
    t.integer "shares_owned", default: 0, null: false
    t.integer "paid_up_shares", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_equity_accounts_on_account_number", unique: true
    t.index ["equity_account_id"], name: "index_equity_accounts_on_equity_account_id"
    t.index ["member_id", "share_product_id"], name: "index_equity_accounts_on_member_id_and_share_product_id", unique: true
    t.index ["member_id"], name: "index_equity_accounts_on_member_id"
    t.index ["share_product_id"], name: "index_equity_accounts_on_share_product_id"
  end

  create_table "equity_products", force: :cascade do |t|
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
    t.index ["equity_ledger_id"], name: "index_equity_products_on_equity_ledger_id"
    t.index ["product_code"], name: "index_equity_products_on_product_code", unique: true
  end

  create_table "equity_transactions", force: :cascade do |t|
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
    t.integer "posted_by_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_equity_transactions_on_cash_account_id"
    t.index ["entry_id"], name: "index_equity_transactions_on_entry_id"
    t.index ["reference_number"], name: "index_equity_transactions_on_reference_number", unique: true
    t.index ["share_capital_account_id"], name: "index_equity_transactions_on_share_capital_account_id"
  end

  create_table "ledgers", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_code", null: false
    t.boolean "contra", default: false
    t.enum "account_type", null: false, enum_type: "account_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ancestry"
    t.index ["account_code"], name: "index_ledgers_on_account_code", unique: true
    t.index ["ancestry"], name: "index_ledgers_on_ancestry"
  end

  create_table "loan_applications", force: :cascade do |t|
    t.bigint "cooperative_id", null: false
    t.bigint "member_id"
    t.bigint "loan_product_id"
    t.string "uuid", null: false
    t.string "status", default: "draft", null: false
    t.integer "current_step", default: 0
    t.decimal "amount_cents", precision: 15, scale: 2
    t.string "amount_currency", default: "PHP"
    t.decimal "interest_rate", precision: 5, scale: 2
    t.integer "term_months"
    t.date "submitted_at"
    t.date "approved_at"
    t.text "notes"
    t.jsonb "sources_of_income", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference_number"
    t.index ["cooperative_id"], name: "index_loan_applications_on_cooperative_id"
    t.index ["loan_product_id"], name: "index_loan_applications_on_loan_product_id"
    t.index ["member_id"], name: "index_loan_applications_on_member_id"
    t.index ["reference_number"], name: "index_loan_applications_on_reference_number", unique: true
    t.index ["uuid"], name: "index_loan_applications_on_uuid", unique: true
  end

  create_table "loan_charges", force: :cascade do |t|
    t.bigint "loan_product_id", null: false
    t.string "name", null: false
    t.string "charge_type", default: "fixed", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_product_id"], name: "index_loan_charges_on_loan_product_id"
  end

  create_table "loan_co_makers", force: :cascade do |t|
    t.bigint "loan_application_id", null: false
    t.bigint "member_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_application_id", "member_id"], name: "index_loan_co_makers_on_loan_application_id_and_member_id", unique: true
    t.index ["loan_application_id"], name: "index_loan_co_makers_on_loan_application_id"
    t.index ["member_id"], name: "index_loan_co_makers_on_member_id"
  end

  create_table "loan_collaterals", force: :cascade do |t|
    t.bigint "loan_application_id", null: false
    t.string "category", null: false
    t.string "name"
    t.text "description"
    t.decimal "assessed_value_cents", precision: 15, scale: 2
    t.string "assessed_value_currency", default: "PHP"
    t.decimal "pin_lat", precision: 10, scale: 7
    t.decimal "pin_lng", precision: 10, scale: 7
    t.string "address"
    t.jsonb "details", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_application_id"], name: "index_loan_collaterals_on_loan_application_id"
  end

  create_table "loan_payments", force: :cascade do |t|
    t.bigint "loan_id", null: false
    t.string "reference_number", null: false
    t.decimal "amount_cents", precision: 15, scale: 2, null: false
    t.string "amount_currency", default: "PHP"
    t.decimal "principal_cents", precision: 15, scale: 2, default: "0.0", null: false
    t.string "principal_currency", default: "PHP"
    t.decimal "interest_cents", precision: 15, scale: 2, default: "0.0", null: false
    t.string "interest_currency", default: "PHP"
    t.decimal "penalty_cents", precision: 15, scale: 2, default: "0.0", null: false
    t.string "penalty_currency", default: "PHP"
    t.date "payment_date", null: false
    t.bigint "entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_loan_payments_on_entry_id"
    t.index ["loan_id"], name: "index_loan_payments_on_loan_id"
    t.index ["reference_number"], name: "index_loan_payments_on_reference_number", unique: true
  end

  create_table "loan_products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "interest_rate", precision: 5, scale: 2, null: false
    t.string "interest_calculation", default: "straight_line", null: false
    t.integer "max_term_months", default: 12, null: false
    t.boolean "requires_collateral", default: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "loan_repayment_schedules", force: :cascade do |t|
    t.bigint "loan_application_id", null: false
    t.integer "sequence", null: false
    t.date "due_date", null: false
    t.decimal "principal_cents", precision: 15, scale: 2, null: false
    t.string "principal_currency", default: "PHP"
    t.decimal "interest_cents", precision: 15, scale: 2, null: false
    t.string "interest_currency", default: "PHP"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_application_id", "sequence"], name: "idx_on_loan_application_id_sequence_2316d64776", unique: true
    t.index ["loan_application_id"], name: "index_loan_repayment_schedules_on_loan_application_id"
  end

  create_table "loans", force: :cascade do |t|
    t.bigint "loan_application_id", null: false
    t.bigint "member_id", null: false
    t.bigint "loan_product_id", null: false
    t.decimal "principal_cents", precision: 15, scale: 2, null: false
    t.string "principal_currency", default: "PHP"
    t.decimal "interest_rate", precision: 5, scale: 2, null: false
    t.string "interest_calculation", null: false
    t.integer "term_months", null: false
    t.decimal "outstanding_principal_cents", precision: 15, scale: 2, null: false
    t.string "outstanding_principal_currency", default: "PHP"
    t.string "status", default: "active", null: false
    t.date "disbursed_at"
    t.string "reference_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_application_id"], name: "index_loans_on_loan_application_id"
    t.index ["loan_product_id"], name: "index_loans_on_loan_product_id"
    t.index ["member_id"], name: "index_loans_on_member_id"
    t.index ["reference_number"], name: "index_loans_on_reference_number", unique: true
  end

  create_table "member_addresses", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "house_street", null: false
    t.string "barangay", null: false
    t.string "city", null: false
    t.string "province", null: false
    t.string "region", null: false
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_member_addresses_on_member_id"
  end

  create_table "member_identifications", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "id_type", null: false
    t.string "id_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id_type", "id_number"], name: "index_member_identifications_on_id_type_and_id_number", unique: true
    t.index ["member_id"], name: "index_member_identifications_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.string "suffix"
    t.date "birth_date", null: false
    t.string "gender", null: false
    t.string "civil_status", null: false
    t.string "mobile_number", null: false
    t.string "email_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_members_on_email_address", unique: true
  end

  create_table "membership_applications", force: :cascade do |t|
    t.string "uuid", null: false
    t.bigint "cooperative_id", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "signature_specimens", default: [], null: false
    t.integer "current_step", default: 0, null: false
    t.jsonb "profile_images", default: [], null: false
    t.jsonb "sources_of_income", default: [], null: false
    t.index ["cooperative_id"], name: "index_membership_applications_on_cooperative_id"
    t.index ["uuid"], name: "index_membership_applications_on_uuid", unique: true
  end

  create_table "running_balances", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "ledger_id", null: false
    t.date "as_of_date", null: false
    t.integer "balance_cents", null: false
    t.string "balance_currency", limit: 3, default: "PHP", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "as_of_date"], name: "idx_running_balances_on_account_date", unique: true, where: "(account_id IS NOT NULL)"
    t.index ["account_id"], name: "index_running_balances_on_account_id"
    t.index ["ledger_id", "as_of_date"], name: "idx_running_balances_on_ledger_date", unique: true, where: "(account_id IS NULL)"
    t.index ["ledger_id"], name: "index_running_balances_on_ledger_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "treasury_cash_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cash_account_id", null: false
    t.date "date", null: false
    t.string "status", default: "open", null: false
    t.datetime "opened_at", null: false
    t.datetime "closed_at"
    t.decimal "beginning_balance_cents", precision: 15, scale: 2
    t.decimal "ending_balance_cents", precision: 15, scale: 2
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "counts", default: []
    t.index ["cash_account_id"], name: "index_treasury_cash_sessions_on_cash_account_id"
    t.index ["user_id", "cash_account_id", "date"], name: "idx_cash_sessions_on_user_account_date", unique: true
    t.index ["user_id"], name: "index_treasury_cash_sessions_on_user_id"
  end

  create_table "treasury_savings_accounts", force: :cascade do |t|
    t.bigint "savings_product_id", null: false
    t.string "depositor_type", null: false
    t.bigint "depositor_id", null: false
    t.integer "account_type", default: 0, null: false
    t.string "status", default: "active", null: false
    t.string "account_number", null: false
    t.datetime "opened_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "liability_account_id"
    t.bigint "interest_expense_account_id"
    t.index ["account_number"], name: "index_treasury_savings_accounts_on_account_number", unique: true
    t.index ["depositor_type", "depositor_id"], name: "idx_savings_accounts_on_depositor"
    t.index ["interest_expense_account_id"], name: "index_treasury_savings_accounts_on_interest_expense_account_id"
    t.index ["liability_account_id"], name: "index_treasury_savings_accounts_on_liability_account_id"
    t.index ["savings_product_id"], name: "index_treasury_savings_accounts_on_savings_product_id"
  end

  create_table "treasury_savings_product_interest_rates", force: :cascade do |t|
    t.bigint "savings_product_id", null: false
    t.decimal "rate", precision: 8, scale: 4, null: false
    t.boolean "current", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["savings_product_id"], name: "idx_on_savings_product_id_06a7ca0e75"
  end

  create_table "treasury_savings_products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "liability_ledger_id"
    t.bigint "interest_expense_ledger_id"
    t.index ["interest_expense_ledger_id"], name: "index_treasury_savings_products_on_interest_expense_ledger_id"
    t.index ["liability_ledger_id"], name: "index_treasury_savings_products_on_liability_ledger_id"
  end

  create_table "treasury_savings_transactions", force: :cascade do |t|
    t.bigint "savings_account_id", null: false
    t.integer "transaction_type", null: false
    t.decimal "amount_cents", precision: 15, scale: 2, null: false
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
    t.index ["entry_id"], name: "index_treasury_savings_transactions_on_entry_id"
    t.index ["reference_number"], name: "index_treasury_savings_transactions_on_reference_number", unique: true
    t.index ["savings_account_id"], name: "index_treasury_savings_transactions_on_savings_account_id"
  end

  create_table "treasury_time_deposit_products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "minimum_deposit_cents", default: 0, null: false
    t.string "minimum_deposit_currency", default: "PHP", null: false
    t.decimal "interest_rate", precision: 8, scale: 4, null: false
    t.integer "term_in_days", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "treasury_time_deposits", force: :cascade do |t|
    t.string "depositor_type", null: false
    t.bigint "depositor_id", null: false
    t.bigint "time_deposit_product_id", null: false
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "PHP", null: false
    t.decimal "interest_rate", precision: 8, scale: 4, null: false
    t.date "matured_on"
    t.integer "interest_earned_cents", default: 0
    t.string "interest_earned_currency", default: "PHP", null: false
    t.string "status", default: "pending", null: false
    t.datetime "opened_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["depositor_type", "depositor_id"], name: "index_treasury_time_deposits_on_depositor"
    t.index ["time_deposit_product_id"], name: "index_treasury_time_deposits_on_time_deposit_product_id"
  end

  create_table "treasury_vault_transfers", force: :cascade do |t|
    t.bigint "cash_session_id", null: false
    t.string "direction", null: false
    t.decimal "amount_cents", precision: 15, scale: 2, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending", null: false
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.bigint "voucher_id"
    t.index ["approved_by_id"], name: "index_treasury_vault_transfers_on_approved_by_id"
    t.index ["cash_session_id"], name: "index_treasury_vault_transfers_on_cash_session_id"
    t.index ["voucher_id"], name: "index_treasury_vault_transfers_on_voucher_id"
  end

  create_table "treasury_vouchers", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "cash_session_id", null: false
    t.string "voucher_number", null: false
    t.string "status", default: "pending", null: false
    t.decimal "amount_cents", precision: 15, scale: 2, null: false
    t.string "amount_currency", default: "PHP", null: false
    t.text "description"
    t.bigint "cash_account_id", null: false
    t.bigint "entry_id"
    t.datetime "posted_at"
    t.string "counterparty_type"
    t.bigint "counterparty_id"
    t.string "category", null: false
    t.string "transactable_type"
    t.bigint "transactable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_treasury_vouchers_on_cash_account_id"
    t.index ["cash_session_id"], name: "index_treasury_vouchers_on_cash_session_id"
    t.index ["counterparty_type", "counterparty_id"], name: "idx_vouchers_on_counterparty"
    t.index ["entry_id"], name: "index_treasury_vouchers_on_entry_id"
    t.index ["status"], name: "index_treasury_vouchers_on_status"
    t.index ["transactable_type", "transactable_id"], name: "idx_vouchers_on_transactable"
    t.index ["type"], name: "index_treasury_vouchers_on_type"
    t.index ["voucher_number"], name: "index_treasury_vouchers_on_voucher_number", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "accounting_cash_accounts", "accounts"
  add_foreign_key "accounting_cash_accounts", "users"
  add_foreign_key "accounts", "ledgers"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "amount_lines", "accounts"
  add_foreign_key "amount_lines", "entries"
  add_foreign_key "cooperatives", "accounts", column: "vault_account_id"
  add_foreign_key "equity_accounts", "accounts", column: "equity_account_id"
  add_foreign_key "equity_accounts", "equity_products", column: "share_product_id"
  add_foreign_key "equity_accounts", "members"
  add_foreign_key "equity_products", "ledgers", column: "equity_ledger_id"
  add_foreign_key "equity_transactions", "accounts", column: "cash_account_id"
  add_foreign_key "equity_transactions", "entries"
  add_foreign_key "equity_transactions", "equity_accounts", column: "share_capital_account_id"
  add_foreign_key "loan_applications", "cooperatives"
  add_foreign_key "loan_applications", "loan_products"
  add_foreign_key "loan_applications", "members"
  add_foreign_key "loan_charges", "loan_products"
  add_foreign_key "loan_co_makers", "loan_applications"
  add_foreign_key "loan_co_makers", "members"
  add_foreign_key "loan_collaterals", "loan_applications"
  add_foreign_key "loan_payments", "entries"
  add_foreign_key "loan_payments", "loans"
  add_foreign_key "loan_repayment_schedules", "loan_applications"
  add_foreign_key "loans", "loan_applications"
  add_foreign_key "loans", "loan_products"
  add_foreign_key "loans", "members"
  add_foreign_key "member_addresses", "members"
  add_foreign_key "member_identifications", "members"
  add_foreign_key "membership_applications", "cooperatives"
  add_foreign_key "running_balances", "accounts"
  add_foreign_key "running_balances", "ledgers"
  add_foreign_key "sessions", "users"
  add_foreign_key "treasury_cash_sessions", "accounts", column: "cash_account_id"
  add_foreign_key "treasury_cash_sessions", "users"
  add_foreign_key "treasury_savings_accounts", "accounts", column: "interest_expense_account_id"
  add_foreign_key "treasury_savings_accounts", "accounts", column: "liability_account_id"
  add_foreign_key "treasury_savings_accounts", "treasury_savings_products", column: "savings_product_id"
  add_foreign_key "treasury_savings_product_interest_rates", "treasury_savings_products", column: "savings_product_id"
  add_foreign_key "treasury_savings_products", "ledgers", column: "interest_expense_ledger_id"
  add_foreign_key "treasury_savings_products", "ledgers", column: "liability_ledger_id"
  add_foreign_key "treasury_savings_transactions", "treasury_savings_accounts", column: "savings_account_id"
  add_foreign_key "treasury_time_deposits", "treasury_time_deposit_products", column: "time_deposit_product_id"
  add_foreign_key "treasury_vault_transfers", "treasury_cash_sessions", column: "cash_session_id"
  add_foreign_key "treasury_vault_transfers", "treasury_vouchers", column: "voucher_id"
  add_foreign_key "treasury_vault_transfers", "users", column: "approved_by_id"
  add_foreign_key "treasury_vouchers", "accounts", column: "cash_account_id"
  add_foreign_key "treasury_vouchers", "entries"
  add_foreign_key "treasury_vouchers", "treasury_cash_sessions", column: "cash_session_id"
end
