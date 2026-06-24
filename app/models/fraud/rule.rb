class Fraud::Rule < ApplicationRecord
  self.table_name = "fraud_rules"

  include CooperativeScoped

  has_many :incidents, class_name: "Fraud::Incident", foreign_key: :rule_id, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :cooperative_id }
  validates :rule_type, presence: true
  validates :severity, inclusion: { in: %w[low medium high critical] }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :by_severity, -> { order(severity: :desc) }
end
