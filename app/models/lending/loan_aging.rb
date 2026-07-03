module Lending
  class LoanAging < ApplicationRecord
    self.table_name = "loan_agings"
    include CooperativeScoped

    belongs_to :loan
    belongs_to :loan_aging_group

    validates :days_past_due, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :outstanding_principal_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :outstanding_interest_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :penalty_amount_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :total_exposure_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :calculated_at, presence: true

    scope :delinquent, -> { joins(:loan_aging_group).where("loan_aging_groups.min_days > 0") }
    scope :by_group, ->(group_id) { where(loan_aging_group_id: group_id) if group_id.present? }

    delegate :name, to: :loan_aging_group, prefix: :group
  end
end
