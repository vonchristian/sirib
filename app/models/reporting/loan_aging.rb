module Reporting
  class LoanAging < ApplicationRecord
    self.table_name = "reporting_loan_agings"
    self.primary_key = "loan_id"

    belongs_to :loan, class_name: "Lending::Loan", foreign_key: :loan_id
    belongs_to :member, class_name: "Membership::Member", foreign_key: :member_id, optional: true

    monetize :outstanding_principal_cents
    monetize :total_exposure_cents

    scope :by_cooperative, ->(coop) { where(cooperative_id: coop.id) }
    scope :delinquent, -> { where("days_past_due > 0") }
    scope :by_group, ->(name) { where(aging_group_name: name) }

    def readonly?
      true
    end

    def self.refresh
      connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_loan_agings")
    end
  end
end