module Lending
  class LoanRestructureCase < ApplicationRecord
    self.table_name = "loan_restructure_cases"
    include CooperativeScoped

    belongs_to :loan
    belongs_to :new_loan, class_name: "Lending::Loan", optional: true
    belongs_to :requested_by, class_name: "User", optional: true
    belongs_to :approved_by, class_name: "User", optional: true

    validates :restructure_type, inclusion: { in: %w[modification refinance hybrid] }
    validates :status, inclusion: { in: %w[draft submitted under_review approved rejected executed failed] }

    scope :draft, -> { where(status: "draft") }
    scope :submitted, -> { where(status: "submitted") }
    scope :under_review, -> { where(status: "under_review") }
    scope :approved, -> { where(status: "approved") }
    scope :rejected, -> { where(status: "rejected") }
    scope :executed, -> { where(status: "executed") }
    scope :pending_decision, -> { where(status: %w[submitted under_review]) }
    scope :by_type, ->(type) { where(restructure_type: type) }

    def draft?
      status == "draft"
    end

    def submitted?
      status == "submitted"
    end

    def under_review?
      status == "under_review"
    end

    def approved?
      status == "approved"
    end

    def rejected?
      status == "rejected"
    end

    def executed?
      status == "executed"
    end

    def failed?
      status == "failed"
    end

    def editable?
      draft? || rejected?
    end

    def modification?
      restructure_type == "modification"
    end

    def refinance?
      restructure_type == "refinance"
    end

    def hybrid?
      restructure_type == "hybrid"
    end

    def submit!
      update!(status: "submitted", submitted_at: Time.current)
    end

    def review!
      update!(status: "under_review")
    end

    def approve!(approver:)
      update!(status: "approved", approved_by: approver, reviewed_at: Time.current)
    end

    def reject!(approver:)
      update!(status: "rejected", approved_by: approver, reviewed_at: Time.current)
    end

    def execute!
      update!(status: "executed", executed_at: Time.current)
    end

    def fail!
      update!(status: "failed")
    end
  end
end
