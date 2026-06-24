module Lending
  class LoanLink < ApplicationRecord
    self.table_name = "loan_links"
    include CooperativeScoped

    belongs_to :from_loan, class_name: "Lending::Loan"
    belongs_to :to_loan, class_name: "Lending::Loan"

    monetize :amount_cents

    validates :link_type, inclusion: { in: %w[modification refinance hybrid] }
    validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :to_loan_id, uniqueness: { scope: :from_loan_id, message: "link already exists between these loans" }

    scope :modifications, -> { where(link_type: "modification") }
    scope :refinances, -> { where(link_type: "refinance") }
    scope :hybrids, -> { where(link_type: "hybrid") }

    scope :outgoing, ->(loan) { where(from_loan: loan) }
    scope :incoming, ->(loan) { where(to_loan: loan) }
  end
end
