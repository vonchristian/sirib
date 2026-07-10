class Current < ActiveSupport::CurrentAttributes
  attribute :session, :cash_session, :branch, :cooperative,
            :portal_session, :member, :request_id
  delegate :user, to: :session, allow_nil: true
end
