class Cooperative < ApplicationRecord
  has_many :membership_applications, class_name: "Membership::Application", dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :branches, class_name: "Management::Branch", dependent: :destroy
  belongs_to :vault_account, class_name: "Accounting::Account", optional: true

  validates :name, presence: true

  scope :active, -> { where(status: "active") }

  def deactivate!
    update!(status: "inactive")
  end

  def activate!
    update!(status: "active")
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name status created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[users branches]
  end

end
