module Management
  class RiskIndicator < ApplicationRecord
    self.table_name = "management_risk_indicators"
    include CooperativeScoped

    belongs_to :branch, class_name: "Management::Branch", optional: true

    validates :indicator_type, :as_of_date, presence: true
    validates :indicator_type, uniqueness: { scope: [:branch_id, :as_of_date, :cooperative_id] }

    enum :status, { normal: "normal", elevated: "elevated", critical: "critical" }
  end
end
