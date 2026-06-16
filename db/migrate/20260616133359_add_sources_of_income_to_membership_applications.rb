class AddSourcesOfIncomeToMembershipApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :membership_applications, :sources_of_income, :jsonb, null: false, default: []
  end
end
