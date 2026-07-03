module Lending
  class LoanAgingSnapshot < ApplicationRecord
    self.table_name = "loan_aging_snapshots"
    include CooperativeScoped

    belongs_to :loan_aging_group

    validates :snapshot_date, presence: true
    validates :loan_count, numericality: { greater_than_or_equal_to: 0 }
    validates :member_count, numericality: { greater_than_or_equal_to: 0 }
    validates :principal_amount_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :interest_amount_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :total_exposure_cents, numericality: { greater_than_or_equal_to: 0 }

    scope :for_date, ->(date) { where(snapshot_date: date) }
    scope :chronological, -> { order(:snapshot_date) }

    delegate :name, to: :loan_aging_group, prefix: :group
  end
end
