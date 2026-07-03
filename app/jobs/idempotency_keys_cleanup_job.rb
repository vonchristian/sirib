class IdempotencyKeysCleanupJob < ApplicationJob
  queue_as :default

  def perform
    IdempotencyKey.expired.in_batches.delete_all
  end
end
