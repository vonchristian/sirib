class ChangeProfileImageDataToImagesOnMembershipApplications < ActiveRecord::Migration[8.0]
  def change
    remove_column :membership_applications, :profile_image_data, :text
    add_column :membership_applications, :profile_images, :jsonb, default: [], null: false
  end
end
