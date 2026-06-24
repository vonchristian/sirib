class Compliance::Control < ApplicationRecord
  self.table_name = "compliance_controls"

  include CooperativeScoped

  has_many :evidences, class_name: "Compliance::Evidence", foreign_key: :control_id, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :cooperative_id }
  validates :category, inclusion: { in: %w[authentication authorization encryption audit logging security fraud] }, allow_nil: true
  validates :frequency, inclusion: { in: %w[daily weekly monthly quarterly yearly] }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
end
