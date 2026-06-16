class Member < ApplicationRecord
  has_one :address, class_name: "MemberAddress", dependent: :destroy
  has_many :identifications, class_name: "MemberIdentification", dependent: :destroy
  has_one_attached :signature
  has_one_attached :profile_image

  accepts_nested_attributes_for :address, allow_destroy: true
  accepts_nested_attributes_for :identifications, allow_destroy: true, reject_if: :all_blank

  validates :first_name, :last_name, :birth_date, :gender, :civil_status, :mobile_number, presence: true
  validates :email_address, uniqueness: true, allow_blank: true
  validates :gender, inclusion: { in: %w[male female] }
  validates :civil_status, inclusion: { in: %w[single married divorced widowed] }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def name
    [first_name, middle_name, last_name].compact.join(" ")
  end
end
