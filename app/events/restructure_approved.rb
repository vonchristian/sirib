class RestructureApproved < DomainEvent
  attribute :restructure_case_id, :integer
  attribute :approved_by, :integer
  attribute :source, :string

  validates :restructure_case_id, presence: true

  def replay(loan)
    loan.update!(status: :restructure_requested)
  end
end
