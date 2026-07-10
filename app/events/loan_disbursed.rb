class LoanDisbursed < DomainEvent
  attribute :amount_cents, :integer
  attribute :disbursement_method, :string
  attribute :disbursed_to_account_id, :integer

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :disbursement_method, presence: true

  def replay(loan)
    loan.update!(
      disbursed_at: occurred_at,
      outstanding_principal_cents: amount_cents
    )
  end
end
