class Cooperative < ApplicationRecord
  has_many :membership_applications, dependent: :destroy
  validates :name, presence: true
end
