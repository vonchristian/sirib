class RestructureRejected < DomainEvent
  attribute :restructure_case_id, :integer
  attribute :rejected_by, :integer
  attribute :reason, :string
  attribute :source, :string

  validates :restructure_case_id, presence: true

  def replay(loan)
  end
end
