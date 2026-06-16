class AddReferenceNumberToLoanApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :loan_applications, :reference_number, :string
    add_index :loan_applications, :reference_number, unique: true
  end
end
