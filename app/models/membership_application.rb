class MembershipApplication < ApplicationRecord
  belongs_to :cooperative

  attribute :identifications, :jsonb, default: []
  attribute :signature_specimens, :jsonb, default: []
  attribute :profile_images, :jsonb, default: []
  attribute :sources_of_income, :jsonb, default: []

  validates :status, inclusion: { in: %w[draft completed approved rejected] }

  def signature_specimens=(value)
    if value.is_a?(String)
      super(JSON.parse(value))
    else
      super(value)
    end
  end

  def profile_images=(value)
    if value.is_a?(String)
      super(JSON.parse(value))
    else
      super(value)
    end
  end

  def sources_of_income=(value)
    if value.is_a?(String)
      super(JSON.parse(value))
    else
      super(value)
    end
  end

  before_validation :assign_uuid, on: :create

  scope :draft, -> { where(status: "draft") }
  scope :completed, -> { where(status: "completed") }

  def step_valid?(step)
    case step
    when 0 then first_name? && last_name? && birth_date? && gender? && civil_status?
    when 1 then house_street? && barangay? && city? && province? && region?
    when 2 then identifications.any?
    when 3 then sources_of_income.any?
    when 4 then signature_specimens.length >= 3
    when 5 then profile_images.length >= 1
    else true
    end
  end

  def complete?
    (0..5).all? { |s| step_valid?(s) }
  end

  private

  def assign_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
