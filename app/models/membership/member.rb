module Membership
  class Member < ApplicationRecord
    self.table_name = "members"
    include CooperativeScoped

    include PgSearch::Model

    attr_accessor :signature_data

    def self.model_name
      @_model_name ||= ActiveModel::Name.new(self, nil, "Member")
    end

    belongs_to :branch, class_name: "Management::Branch", optional: true

    has_one :address, class_name: "Membership::Address", dependent: :destroy
    has_many :identifications, class_name: "Membership::Identification", dependent: :destroy
    has_many_attached :signatures
    has_one_attached :profile_image

    accepts_nested_attributes_for :address, allow_destroy: true
    accepts_nested_attributes_for :identifications, allow_destroy: true, reject_if: :all_blank

    validates :first_name, :last_name, :birth_date, :gender, :civil_status, :mobile_number, presence: true
    validates :email_address, uniqueness: true, allow_blank: true
    validates :gender, inclusion: { in: %w[male female] }
    validates :civil_status, inclusion: { in: %w[single married divorced widowed] }

    normalizes :email_address, with: ->(e) { e.strip.downcase }

    validate :must_have_bir_identification, on: :create

    before_create :assign_member_identifier

    pg_search_scope :search,
      against: [ :first_name, :middle_name, :last_name, :mobile_number, :email_address, :member_identifier ],
      associated_against: { address: [ :city, :barangay, :province ] },
      using: { tsearch: { prefix: true, any_word: true, normalization: 2 } }

    def must_have_bir_identification
      unless identifications.any? { |id| id.id_type == "BIR" }
        errors.add(:identifications, "must include at least one BIR identification")
      end
    end

    def name
      [ first_name, middle_name, last_name ].compact.join(" ")
    end

    private

    def assign_member_identifier
      return if member_identifier.present?
      date_part = Time.current.strftime("%y%m")
      loop do
        random_part = SecureRandom.hex(3).upcase
        self.member_identifier = "MBR-#{date_part}-#{random_part}"
        break unless self.class.exists?(member_identifier: member_identifier)
      end
    end
  end
end
