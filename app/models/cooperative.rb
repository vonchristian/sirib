class Cooperative < ApplicationRecord
  has_many :membership_applications, class_name: "Membership::Application", dependent: :destroy
  belongs_to :vault_account, class_name: "Accounting::Account", optional: true

  validates :name, presence: true
end
