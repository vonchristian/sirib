module Lending
  class LoanProduct < ApplicationRecord
    self.table_name = "loan_products"
    include CooperativeScoped

    has_many :loan_applications, dependent: :restrict_with_error
    has_many :loans, dependent: :restrict_with_error
    has_many :loan_charges, dependent: :destroy

    accepts_nested_attributes_for :loan_charges, allow_destroy: true, reject_if: :all_blank

    validates :name, presence: true
    validates :interest_rate, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
    validates :interest_calculation, inclusion: { in: %w[straight_line declining_balance] }
    validates :max_term_months, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: %w[active inactive] }

    scope :active, -> { where(status: "active") }
  end
end
