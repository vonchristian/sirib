module Lending
  class LoanCollateral < ApplicationRecord
    self.table_name = "loan_collaterals"

    belongs_to :loan_application
    has_many_attached :images

    CATEGORIES = %w[real_property vehicle equipment inventory guarantee others].freeze

    validates :category, presence: true, inclusion: { in: CATEGORIES }
    validates :name, presence: true
    validates :assessed_value_cents, numericality: { greater_than: 0 }, allow_nil: true
  end
end
