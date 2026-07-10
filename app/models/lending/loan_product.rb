module Lending
  class LoanProduct < ApplicationRecord
    self.table_name = "loan_products"
    include CooperativeScoped

    has_many :loan_applications, dependent: :restrict_with_error
    has_many :loans, dependent: :restrict_with_error
    has_many :loan_charges, dependent: :destroy
    has_many :versions, class_name: "Lending::LoanProductVersion"

    accepts_nested_attributes_for :loan_charges, allow_destroy: true, reject_if: :all_blank

    validates :name, presence: true
    validates :interest_rate, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
    validates :interest_calculation, inclusion: { in: %w[straight_line declining_balance] }
    validates :max_term_months, numericality: { greater_than: 0 }
    validates :status, inclusion: { in: %w[active inactive] }

    scope :active, -> { where(status: "active") }

    before_update :create_version_snapshot, if: :changed?

    def current_snapshot
      attributes.except("id", "cooperative_id", "created_at", "updated_at", "version")
    end

    private

    def create_version_snapshot
      self.version = (version || 1) + 1
      versions.create!(
        version: version,
        snapshot: current_snapshot,
        modified_by: Current.user,
        change_reason: "Updated via #{self.class.name}"
      )
    end
  end
end
