class LoanWrittenOff < DomainEvent
  attribute :written_off_by_id, :integer
  attribute :reason, :string
  attribute :amount_cents, :integer
  attribute :approval_reference, :string

  validates :written_off_by_id, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }

  def replay(loan)
    loan.update!(status: :written_off, outstanding_principal_cents: 0)
  end
end
