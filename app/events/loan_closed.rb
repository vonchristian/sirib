class LoanClosed < DomainEvent
  attribute :closed_by_id, :integer
  attribute :reason, :string
  attribute :final_principal_cents, :integer
  attribute :final_interest_cents, :integer

  validates :closed_by_id, presence: true

  def replay(loan)
    loan.update!(status: :paid)
  end
end
