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

ActiveRecord::Schema[8.0].define(version: 2026_06_10_101403) do
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

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "accounting_cash_accounts", "accounts"
  add_foreign_key "accounting_cash_accounts", "users"
  add_foreign_key "accounts", "ledgers"
  add_foreign_key "amount_lines", "accounts"
  add_foreign_key "amount_lines", "entries"
  add_foreign_key "running_balances", "accounts"
  add_foreign_key "running_balances", "ledgers"
  add_foreign_key "sessions", "users"
end
