module Lending
  class LoanApplication < ApplicationRecord
    self.table_name = "loan_applications"

    belongs_to :cooperative
    belongs_to :member, class_name: "Membership::Member", optional: true
    belongs_to :loan_product, optional: true
    has_many :loan_collaterals, dependent: :destroy
    has_many :loan_repayment_schedules, dependent: :destroy
    has_many :loans, dependent: :restrict_with_error
    has_many :loan_co_makers, dependent: :destroy

    accepts_nested_attributes_for :loan_collaterals, allow_destroy: true, reject_if: :all_blank
    accepts_nested_attributes_for :loan_repayment_schedules, allow_destroy: true
    accepts_nested_attributes_for :loan_co_makers, allow_destroy: true, reject_if: :all_blank

    attribute :sources_of_income, :jsonb, default: []

    validates :uuid, presence: true, uniqueness: true
    validates :status, inclusion: { in: %w[draft submitted verified approved rejected disbursed] }
    validates :amount_cents, numericality: { greater_than: 0 }, allow_nil: true
    validates :interest_rate, numericality: { greater_than: 0 }, allow_nil: true
    validates :term_months, numericality: { greater_than: 0 }, allow_nil: true

    STEP_KEYS = %w[loan_details sources_of_income co_makers collaterals repayment_schedule].freeze

    def sources_of_income=(value)
      if value.is_a?(String)
        super(JSON.parse(value))
      else
        super(value)
      end
    end

    before_validation :assign_uuid, on: :create
    before_validation :assign_reference_number, on: :create
    before_save :reject_blank_income

    scope :draft, -> { where(status: "draft") }
    scope :submitted, -> { where(status: "submitted") }
    scope :approved, -> { where(status: "approved") }

    def draft?
      status == "draft"
    end

    def submitted?
      status == "submitted"
    end

    def approved?
      status == "approved"
    end

    STEP_LABELS = ["Loan Details", "Income Sources", "Co-Makers", "Collaterals", "Schedule"].freeze

    def step_valid?(step)
      case step
      when 0 then member_id? && loan_product_id? && amount_cents.present? && amount_cents > 0 && term_months.present?
      when 1 then sources_of_income.any?
      when 2 then true
      when 3 then loan_product&.requires_collateral? ? loan_collaterals.any? : true
      when 4 then true
      else true
      end
    end

    def complete?
      (0...STEP_KEYS.length).all? { |s| step_valid?(s) }
    end

    def first_incomplete_step
      (0...STEP_KEYS.length).find { |s| !step_valid?(s) }
    end

    def generate_repayment_schedules!
      loan_repayment_schedules.destroy_all
      schedules = RepaymentScheduleCalculator.call(
        amount: BigDecimal(amount_cents) / 100,
        interest_rate: interest_rate,
        term_months: term_months,
        calculation: loan_product.interest_calculation
      )
      schedules.each_with_index do |sched, i|
        loan_repayment_schedules.create!(
          sequence: i + 1,
          due_date: Date.current + (i + 1).months,
          principal_cents: (sched[:principal] * 100).round,
          interest_cents: (sched[:interest] * 100).round
        )
      end
    end

    private

    def assign_uuid
      self.uuid ||= SecureRandom.uuid
    end

    def assign_reference_number
      return if reference_number.present?
      date_part = Time.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(3).upcase
      self.reference_number = "LA-#{date_part}-#{random_part}"
    end

    def reject_blank_income
      self.sources_of_income = sources_of_income.reject { |e| e.values.all?(&:blank?) }
    end
  end
end
