module Lending
  class LoanAgingGroup < ApplicationRecord
    self.table_name = "loan_aging_groups"
    include CooperativeScoped

    has_many :loan_agings, dependent: :restrict_with_error
    has_many :loan_aging_snapshots, dependent: :restrict_with_error

    validates :name, presence: true, uniqueness: { scope: :cooperative_id }
    validates :min_days, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :max_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :display_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validate :max_days_greater_than_min_days

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:display_order) }

    def self.find_bucket(dpd, cooperative_id: nil)
      scope = active.ordered
      scope = scope.where(cooperative_id: cooperative_id) if cooperative_id
      scope.detect { |g| g.covers?(dpd) }
    end

    def covers?(dpd)
      return false unless active?
      return dpd >= min_days if max_days.nil?
      dpd >= min_days && dpd <= max_days
    end

    def range_label
      return "#{min_days} Days" if max_days.nil?
      return "Current" if min_days == 0 && max_days == 0
      "#{min_days}-#{max_days} Days"
    end

    private

    def max_days_greater_than_min_days
      return if max_days.nil?
      if max_days < min_days
        errors.add(:max_days, "must be greater than or equal to min_days")
      end
    end
  end
end
