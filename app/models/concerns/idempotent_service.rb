module IdempotentService
  extend ActiveSupport::Concern

  def with_idempotency(key:)
    return yield unless key

    existing = IdempotencyKey.active.find_by(key: key, cooperative_id: Current.cooperative&.id)
    if existing
      return existing.resource
    end

    result = nil
    IdempotencyKey.transaction do
      result = yield
      idem_key = IdempotencyKey.find_or_initialize_by(key: key, cooperative: Current.cooperative)
      idem_key.update!(
        service: self.class.name,
        resource: result,
        expires_at: 24.hours.from_now
      )
    end

    result
  end
end
