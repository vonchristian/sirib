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

ActiveRecord::Schema[8.0].define(version: 2026_06_16_132610) do
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
  add_foreign_key "member_addresses", "members"
  add_foreign_key "member_identifications", "members"
  add_foreign_key "membership_applications", "cooperatives"
  add_foreign_key "running_balances", "accounts"
  add_foreign_key "running_balances", "ledgers"
  add_foreign_key "sessions", "users"
  add_foreign_key "treasury_time_deposits", "treasury_time_deposit_products", column: "time_deposit_product_id"
end
