class DomainEvent
  include ActiveModel::Attributes
  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations

  attr_reader :aggregate, :actor, :occurred_at, :event_id

  def initialize(aggregate:, actor:, **attributes)
    @aggregate = aggregate
    @actor = actor
    @occurred_at = Time.current
    @event_id = SecureRandom.uuid
    super()
    self.attributes = attributes if attributes.any?
  end

  def event_name
    self.class.name.demodulize.underscore
  end

  def to_loan_event_attributes
    {
      loan: aggregate,
      actor: actor,
      event_type: event_name,
      metadata: serializable_attributes,
      created_at: occurred_at,
      cooperative: aggregate.respond_to?(:cooperative) ? aggregate.cooperative : aggregate.cooperative_id
    }
  end

  def save!
    Lending::LoanEvent.create!(to_loan_event_attributes)
  end

  def replay(loan)
    raise NotImplementedError, "#{self.class} must implement #replay"
  end

  private

  def serializable_attributes
    attributes.except("aggregate", "actor")
  end
end
