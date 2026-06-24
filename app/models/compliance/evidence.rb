class Compliance::Evidence < ApplicationRecord
  self.table_name = "compliance_evidences"

  include CooperativeScoped

  belongs_to :control, class_name: "Compliance::Control"
  belongs_to :verified_by, polymorphic: true, optional: true

  validates :status, inclusion: { in: %w[pending passed failed expired] }, allow_nil: true
  validates :evidence_type, presence: true

  scope :by_recent, -> { order(created_at: :desc) }
  scope :passed, -> { where(status: "passed") }
  scope :failed, -> { where(status: "failed") }
  scope :expired, -> { where("expires_at < ?", Time.current) }
end
