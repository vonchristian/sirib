class LoanApproved < DomainEvent
  attribute :approved_by_id, :integer
  attribute :approval_date, :date
  attribute :approved_amount_cents, :integer
  attribute :notes, :string

  validates :approved_by_id, presence: true

  def replay(loan)
    loan.update!(status: :approved)
  end
end
