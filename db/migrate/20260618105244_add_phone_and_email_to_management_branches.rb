class AddPhoneAndEmailToManagementBranches < ActiveRecord::Migration[8.0]
  def change
    add_column :management_branches, :phone, :string
    add_column :management_branches, :email, :string
  end
end
