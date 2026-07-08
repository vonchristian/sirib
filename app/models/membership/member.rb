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

    # Portal authentication
    has_secure_password(validations: false)
    has_many :portal_sessions, class_name: "Portal::Session", dependent: :destroy
    has_many :portal_enrollment_tokens, class_name: "Portal::EnrollmentToken", dependent: :destroy

    encrypts :otp_secret

    accepts_nested_attributes_for :address, allow_destroy: true
    accepts_nested_attributes_for :identifications, allow_destroy: true, reject_if: :all_blank

    validates :first_name, :last_name, :birth_date, :gender, :civil_status, :mobile_number, presence: true
    validates :email_address, uniqueness: true, allow_blank: true
    validates :gender, inclusion: { in: %w[male female] }
    validates :civil_status, inclusion: { in: %w[single married divorced widowed] }
    validates :portal_status, inclusion: { in: %w[inactive active suspended] }, allow_blank: true

    normalizes :email_address, with: ->(e) { e.strip.downcase }

    validate :must_have_bir_identification, on: :create

    before_create :assign_member_identifier

    pg_search_scope :search,
      against: [ :first_name, :middle_name, :last_name, :mobile_number, :email_address, :member_identifier ],
      associated_against: { address: [ :city, :barangay, :province ] },
      using: { tsearch: { prefix: true, any_word: true, normalization: 2 } }

    scope :portal_active, -> { where(portal_status: "active") }

    def must_have_bir_identification
      unless identifications.any? { |id| id.id_type == "BIR" }
        errors.add(:identifications, "must include at least one BIR identification")
      end
    end

    def name
      [ first_name, middle_name, last_name ].compact.join(" ")
    end

    def portal_active?
      portal_status == "active"
    end

    def portal_suspended?
      portal_status == "suspended"
    end

    def portal_enabled?
      password_digest.present?
    end

    def toggle_portal_access!(enabled:)
      transaction do
        if enabled
          update!(portal_status: "active")
          create_portal_enrollment_token unless has_valid_enrollment_token?
        else
          update!(portal_status: "suspended")
          revoke_all_portal_sessions!
        end
      end
    end

    def has_valid_enrollment_token?
      portal_enrollment_tokens.valid.exists?
    end

    def create_portal_enrollment_token
      portal_enrollment_tokens.create!
    end

    def revoke_all_portal_sessions!
      portal_sessions.active.update_all(revoked_at: Time.current)
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
