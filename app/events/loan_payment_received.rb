class LoanPaymentReceived < DomainEvent
  attribute :amount_cents, :integer
  attribute :principal_cents, :integer
  attribute :interest_cents, :integer
  attribute :penalty_cents, :integer
  attribute :payment_method, :string

  validates :amount_cents, numericality: { greater_than: 0 }

  def replay(loan)
    new_outstanding = loan.outstanding_principal_cents - principal_cents
    loan.update!(outstanding_principal_cents: [ new_outstanding, 0 ].max)
  end
end
