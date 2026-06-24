module Lending
  class LoanEvent < ApplicationRecord
    self.table_name = "loan_events"
    include CooperativeScoped

    belongs_to :loan
    belongs_to :actor, polymorphic: true

    validates :event_type, presence: true
    validates :status, inclusion: { in: %w[draft completed failed reversed] }

    scope :chronological, -> { order(created_at: :asc) }
    scope :reverse_chronological, -> { order(created_at: :desc) }
    scope :by_type, ->(type) { where(event_type: type) }

    EVENT_TYPES = %w[
      restructure_requested
      restructure_submitted
      restructure_approved
      restructure_rejected
      restructure_executed
      modification_completed
      refinance_completed
      hybrid_completed
      schedule_versioned
      loan_link_created
      payoff_computed
      ledger_entry_posted
    ].freeze

    validates :event_type, inclusion: { in: EVENT_TYPES }
  end
end
