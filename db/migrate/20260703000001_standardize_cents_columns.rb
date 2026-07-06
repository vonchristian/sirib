class StandardizeCentsColumns < ActiveRecord::Migration[8.0]
  def up
    verify_no_fractional_cents!

    change_column :loan_payments, :amount_cents, :integer, null: false
    change_column :loan_payments, :principal_cents, :integer, null: false
    change_column :loan_payments, :interest_cents, :integer, null: false
    change_column :loan_payments, :penalty_cents, :integer, null: false

    change_column :loans, :principal_cents, :integer, null: false
    change_column :loans, :outstanding_principal_cents, :integer, null: false

    change_column :treasury_savings_transactions, :amount_cents, :integer, null: false

    remove_column :external_bank_accounts, :current_balance
    rename_column :external_bank_accounts, :current_balance_cents, :balance_cents
    change_column :external_bank_accounts, :balance_cents, :integer, null: false

    remove_column :external_bank_transactions, :amount
    remove_column :external_bank_transactions, :running_balance
    change_column :external_bank_transactions, :amount_cents, :integer, null: false
    change_column :external_bank_transactions, :running_balance_cents, :integer, null: false
  end

  def down
    change_column :loan_payments, :amount_cents, :decimal, precision: nil, scale: nil
    change_column :loan_payments, :principal_cents, :decimal, precision: nil, scale: nil
    change_column :loan_payments, :interest_cents, :decimal, precision: nil, scale: nil
    change_column :loan_payments, :penalty_cents, :decimal, precision: nil, scale: nil

    change_column :loans, :principal_cents, :decimal, precision: nil, scale: nil
    change_column :loans, :outstanding_principal_cents, :decimal, precision: nil, scale: nil

    change_column :treasury_savings_transactions, :amount_cents, :decimal, precision: nil, scale: nil

    add_column :external_bank_accounts, :current_balance, :decimal, precision: nil, scale: nil
    change_column :external_bank_accounts, :balance_cents, :decimal, precision: nil, scale: nil
    rename_column :external_bank_accounts, :balance_cents, :current_balance_cents

    add_column :external_bank_transactions, :amount, :decimal, precision: nil, scale: nil
    add_column :external_bank_transactions, :running_balance, :decimal, precision: nil, scale: nil
    change_column :external_bank_transactions, :amount_cents, :decimal, precision: nil, scale: nil
    change_column :external_bank_transactions, :running_balance_cents, :decimal, precision: nil, scale: nil
  end

  private

  def verify_no_fractional_cents!
    queries = [
      [ "loan_payments", "amount_cents" ],
      [ "loan_payments", "principal_cents" ],
      [ "loan_payments", "interest_cents" ],
      [ "loan_payments", "penalty_cents" ],
      [ "loans", "principal_cents" ],
      [ "loans", "outstanding_principal_cents" ],
      [ "treasury_savings_transactions", "amount_cents" ],
      [ "external_bank_accounts", "current_balance" ],
      [ "external_bank_accounts", "current_balance_cents" ],
      [ "external_bank_transactions", "amount" ],
      [ "external_bank_transactions", "amount_cents" ],
      [ "external_bank_transactions", "running_balance" ],
      [ "external_bank_transactions", "running_balance_cents" ]
    ]

    queries.each do |table, column|
      count = execute("SELECT COUNT(*) FROM #{table} WHERE #{column} IS NOT NULL AND #{column} != ROUND(#{column})").first["count"]
      if count > 0
        raise ActiveRecord::MigrationError,
          "Data integrity error: #{table}.#{column} has #{count} rows with fractional cents. " \
          "Resolve before migrating."
      end
    end
  end
end
