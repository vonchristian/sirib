class RestructureRequested < DomainEvent
  attribute :restructure_type, :string
  attribute :restructure_case_id, :integer

  attr_accessor :proposed_changes

  validates :restructure_type, presence: true
  validates :restructure_case_id, presence: true

  def replay(loan)
    loan.update!(status: :restructure_requested)
  end

  private

  def serializable_attributes
    super.merge("proposed_changes" => proposed_changes)
  end
end
