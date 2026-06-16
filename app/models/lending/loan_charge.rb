module Lending
  class LoanCharge < ApplicationRecord
    self.table_name = "loan_charges"

    belongs_to :loan_product

    validates :name, presence: true
    validates :charge_type, inclusion: { in: %w[percentage fixed] }
    validates :value, numericality: { greater_than: 0 }

    scope :ordered, -> { order(:name) }

    def computed_cents(amount_cents)
      charge_type == "percentage" ? amount_cents * value / 100.0 : value
    end
  end
end
