class Current < ActiveSupport::CurrentAttributes
  attribute :session, :cash_session, :branch, :tenant, :portal_session, :member
  delegate :user, to: :session, allow_nil: true
end
