class AllowNullOnLoanApplicationForeignKeys < ActiveRecord::Migration[8.0]
  def change
    change_column_null :loan_applications, :member_id, true
    change_column_null :loan_applications, :loan_product_id, true
  end
end
