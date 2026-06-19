module Membership
  class Identification < ApplicationRecord
    self.table_name = "member_identifications"

    ID_TYPES = %w[
      BIR National_ID Passport Drivers_License
      UMID PRC_ID Postal_ID Voters_ID
      Senior_Citizen_ID PWD_ID Barangay_Clearance
    ].freeze

    belongs_to :member, class_name: "Membership::Member"
    has_one_attached :file
    has_one_attached :back_file

    validates :id_type, :id_number, presence: true
    validates :id_type, inclusion: { in: ID_TYPES }
    validates :id_number, uniqueness: { scope: :id_type }
  end
end
