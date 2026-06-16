module Treasury
  class SavingsProductInterestRate < ApplicationRecord
    self.table_name = "treasury_savings_product_interest_rates"

    belongs_to :savings_product, class_name: "Treasury::SavingsProduct"

    validates :rate, presence: true, numericality: { greater_than: 0 }

    scope :current, -> { where(current: true) }
  end
end
