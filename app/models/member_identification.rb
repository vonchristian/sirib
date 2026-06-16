class MemberIdentification < ApplicationRecord
  ID_TYPES = %w[
    BIR National_ID Passport Drivers_License
    UMID PRC_ID Postal_ID Voters_ID
    Senior_Citizen_ID PWD_ID Barangay_Clearance
  ].freeze

  belongs_to :member
  has_one_attached :file

  validates :id_type, :id_number, presence: true
  validates :id_type, inclusion: { in: ID_TYPES }
  validates :id_number, uniqueness: { scope: :id_type }
end
