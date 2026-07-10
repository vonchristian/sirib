module Reconciliation
  class Result < ApplicationRecord
    self.table_name = "reconciliation_results"

    include CooperativeScoped

    validates :check_name, presence: true
    validates :status, inclusion: { in: %w[passed failed] }
    validates :checked_at, presence: true

    scope :recent, -> { order(checked_at: :desc) }
    scope :by_check, ->(name) { where(check_name: name) }
    scope :failed, -> { where(status: "failed") }

    def failed?
      status == "failed"
    end
  end
end
