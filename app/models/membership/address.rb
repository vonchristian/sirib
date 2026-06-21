module Membership
  class Address < ApplicationRecord
    self.table_name = "member_addresses"
    include CooperativeScoped

    belongs_to :member, class_name: "Membership::Member"

    validates :house_street, :barangay, :city, :province, :region, presence: true
  end
end
