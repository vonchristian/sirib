module Lending
  class LoanSchedule < ApplicationRecord
    self.table_name = "loan_schedules"
    include CooperativeScoped

    belongs_to :loan

    validates :version, presence: true, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: %w[active superseded] }
    validates :version, uniqueness: { scope: :loan_id }

    scope :active, -> { where(status: "active") }
    scope :superseded, -> { where(status: "superseded") }

    def active?
      status == "active"
    end

    def superseded?
      status == "superseded"
    end
  end
end
