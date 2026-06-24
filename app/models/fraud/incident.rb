class Fraud::Incident < ApplicationRecord
  self.table_name = "fraud_incidents"

  include CooperativeScoped

  belongs_to :rule, class_name: "Fraud::Rule"
  belongs_to :actor, polymorphic: true
  belongs_to :resolved_by, polymorphic: true, optional: true

  validates :incident_type, presence: true
  validates :description, presence: true
  validates :severity, inclusion: { in: %w[low medium high critical] }, allow_nil: true

  scope :unresolved, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :by_severity, -> { order(severity: :desc) }
  scope :by_recent, -> { order(created_at: :desc) }

  def resolved?
    resolved_at.present?
  end

  def resolve!(user:, resolution:)
    update!(resolved_at: Time.current, resolved_by: user, resolution: resolution)
  end
end
