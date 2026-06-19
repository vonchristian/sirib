class Current < ActiveSupport::CurrentAttributes
  attribute :session, :cash_session, :branch, :tenant
  delegate :user, to: :session, allow_nil: true
end
