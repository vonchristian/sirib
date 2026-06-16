class AddCurrentStepToMembershipApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :membership_applications, :current_step, :integer, default: 0, null: false
  end
end
