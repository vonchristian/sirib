class AllowNullOnLoanApplicationAmounts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :loan_applications, :amount_cents, true
    change_column_null :loan_applications, :interest_rate, true
    change_column_null :loan_applications, :term_months, true
  end
end
