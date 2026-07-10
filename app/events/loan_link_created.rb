class LoanLinkCreated < DomainEvent
  attribute :link_id, :integer
  attribute :link_type, :string
  attribute :from_loan_id, :integer
  attribute :to_loan_id, :integer
  attribute :amount_cents, :integer

  validates :link_type, presence: true
  validates :from_loan_id, presence: true
  validates :to_loan_id, presence: true

  def replay(loan)
  end
end
