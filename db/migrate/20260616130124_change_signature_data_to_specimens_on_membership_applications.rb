class ChangeSignatureDataToSpecimensOnMembershipApplications < ActiveRecord::Migration[8.0]
  def change
    remove_column :membership_applications, :signature_data, :text
    add_column :membership_applications, :signature_specimens, :jsonb, default: [], null: false
  end
end
