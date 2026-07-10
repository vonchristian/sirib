module Lending
  class Loan < ApplicationRecord
    self.table_name = "loans"
    include CooperativeScoped

    belongs_to :loan_application
    belongs_to :member, class_name: "Membership::Member"
    belongs_to :loan_product
    has_many :loan_payments, dependent: :restrict_with_error

    has_many :loan_schedules, dependent: :destroy
    has_many :loan_events, dependent: :destroy
    has_many :loan_restructure_cases, dependent: :destroy
    has_many :outgoing_loan_links, class_name: "Lending::LoanLink", foreign_key: :from_loan_id, dependent: :destroy
    has_many :incoming_loan_links, class_name: "Lending::LoanLink", foreign_key: :to_loan_id, dependent: :destroy

    has_one :active_schedule, -> { where(status: "active") }, class_name: "Lending::LoanSchedule"

    validates :principal_cents, numericality: { greater_than: 0 }
    validates :interest_rate, numericality: { greater_than: 0 }
    validates :interest_calculation, inclusion: { in: %w[straight_line declining_balance] }
    validates :term_months, numericality: { greater_than: 0 }
    validates :outstanding_principal_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :status, inclusion: { in: %w[active paid defaulted written_off refinanced modified hybrid_restructured restructure_requested under_review] }
    validates :reference_number, uniqueness: { scope: :cooperative_id }

    before_validation :assign_reference_number, on: :create
    before_create :capture_product_snapshot
    after_commit :recalculate_aging_on_status_change, on: [ :update ], if: :saved_change_to_status?

    scope :active, -> { where(status: "active") }
    scope :paid, -> { where(status: "paid") }
    scope :defaulted, -> { where(status: "defaulted") }
    scope :restructured, -> { where(status: %w[refinanced modified hybrid_restructured]) }
    scope :for_disbursement, -> { where(status: "active", disbursed_at: nil) }
    scope :restructure_requested, -> { where(status: "restructure_requested") }

    RESTRUCTURABLE_STATUSES = %w[active defaulted].freeze
    RESTRUCTURE_LIMIT_EXCLUDED = %w[refinanced modified hybrid_restructured paid written_off].freeze

    def active?
      status == "active"
    end

    def disbursed?
      disbursed_at.present?
    end

    def restructurable?
      RESTRUCTURABLE_STATUSES.include?(status) && restructures_count < max_restructures
    end

    def payment_schedule
      loan_application.loan_repayment_schedules.order(:sequence)
    end

    def current_schedule_version
      loan_schedules.active.first
    end

    def linked_loans
      from_ids = outgoing_loan_links.pluck(:to_loan_id)
      to_ids = incoming_loan_links.pluck(:from_loan_id)
      Lending::Loan.where(id: from_ids + to_ids)
    end

    def lineage
      ancestors = []
      current = self
      while (incoming = current.incoming_loan_links.refinances.or(current.incoming_loan_links.hybrids).first)
        ancestors << incoming.from_loan
        current = incoming.from_loan
      end
      ancestors.reverse + [ self ]
    end

    def increment_restructures!
      increment!(:restructures_count)
    end

    def terms_at_origination
      product_snapshot
    end

    private

    def capture_product_snapshot
      self.product_snapshot = loan_product.current_snapshot
    end

    def recalculate_aging_on_status_change
      Lending::AgingCalculationService.call(loan: self)
    end

    def assign_reference_number
      return if reference_number.present?
      self.reference_number = "LN-#{Time.current.strftime("%Y%m%d")}-#{SecureRandom.hex(3).upcase}"
    end
  end
end
