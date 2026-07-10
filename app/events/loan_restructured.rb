class LoanRestructured < DomainEvent
  attribute :new_principal_cents, :integer
  attribute :new_term_months, :integer
  attribute :new_interest_rate, :decimal
  attribute :old_principal_cents, :integer
  attribute :reason, :string

  validates :new_principal_cents, numericality: { greater_than: 0 }
  validates :new_term_months, numericality: { greater_than: 0 }

  def replay(loan)
    loan.update!(
      principal_cents: new_principal_cents,
      term_months: new_term_months,
      interest_rate: new_interest_rate,
      outstanding_principal_cents: new_principal_cents
    )
  end
end
