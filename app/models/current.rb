class Current < ActiveSupport::CurrentAttributes
  attribute :session, :cash_session, :branch
  delegate :user, to: :session, allow_nil: true
end
