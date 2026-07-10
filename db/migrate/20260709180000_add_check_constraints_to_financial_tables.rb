class AddCheckConstraintsToFinancialTables < ActiveRecord::Migration[8.0]
  LOAN_STATUSES = %w[active paid defaulted written_off refinanced modified hybrid_restructured restructure_requested under_review].freeze

  CONSTRAINTS = {
    "chk_amount_lines_amount_cents_positive" =>
      "ALTER TABLE amount_lines ADD CONSTRAINT chk_amount_lines_amount_cents_positive CHECK (amount_cents > 0)",
    "chk_amount_lines_amount_type_valid" =>
      "ALTER TABLE amount_lines ADD CONSTRAINT chk_amount_lines_amount_type_valid CHECK (amount_type IN (0, 1))",
    "chk_entries_status_valid" =>
      "ALTER TABLE entries ADD CONSTRAINT chk_entries_status_valid CHECK (status IN ('pending', 'posted', 'reversed'))",
    "chk_loans_principal_cents_positive" =>
      "ALTER TABLE loans ADD CONSTRAINT chk_loans_principal_cents_positive CHECK (principal_cents > 0)",
    "chk_loans_outstanding_principal_non_negative" =>
      "ALTER TABLE loans ADD CONSTRAINT chk_loans_outstanding_principal_non_negative CHECK (outstanding_principal_cents >= 0)",
    "chk_loans_term_months_positive" =>
      "ALTER TABLE loans ADD CONSTRAINT chk_loans_term_months_positive CHECK (term_months > 0)",
    "chk_loans_status_valid" =>
      "ALTER TABLE loans ADD CONSTRAINT chk_loans_status_valid CHECK (status IN (#{LOAN_STATUSES.map { |s| "'#{s}'" }.join(', ')}))",
    "chk_loan_payments_amount_cents_positive" =>
      "ALTER TABLE loan_payments ADD CONSTRAINT chk_loan_payments_amount_cents_positive CHECK (amount_cents > 0)",
    "chk_loan_payments_allocation_equals_amount" =>
      "ALTER TABLE loan_payments ADD CONSTRAINT chk_loan_payments_allocation_equals_amount CHECK (principal_cents + interest_cents + penalty_cents = amount_cents)",
    "chk_savings_transactions_amount_cents_non_zero" =>
      "ALTER TABLE treasury_savings_transactions ADD CONSTRAINT chk_savings_transactions_amount_cents_non_zero CHECK (amount_cents != 0)",
    "chk_equity_transactions_shares_positive" =>
      "ALTER TABLE equity_transactions ADD CONSTRAINT chk_equity_transactions_shares_positive CHECK (shares > 0)"
  }.freeze

  def up
    CONSTRAINTS.each_value { |sql| execute(sql) }
  end

  DROPS = {
    "amount_lines" => %w[chk_amount_lines_amount_cents_positive chk_amount_lines_amount_type_valid],
    "entries" => %w[chk_entries_status_valid],
    "loans" => %w[chk_loans_principal_cents_positive chk_loans_outstanding_principal_non_negative chk_loans_term_months_positive chk_loans_status_valid],
    "loan_payments" => %w[chk_loan_payments_amount_cents_positive chk_loan_payments_allocation_equals_amount],
    "treasury_savings_transactions" => %w[chk_savings_transactions_amount_cents_non_zero],
    "equity_transactions" => %w[chk_equity_transactions_shares_positive]
  }.freeze

  def down
    DROPS.each do |table, constraints|
      constraints.each do |name|
        execute("ALTER TABLE #{table} DROP CONSTRAINT IF EXISTS #{name}")
      end
    end
  end
end