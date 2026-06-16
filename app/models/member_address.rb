class MemberAddress < ApplicationRecord
  belongs_to :member

  validates :house_street, :barangay, :city, :province, :region, presence: true
end
