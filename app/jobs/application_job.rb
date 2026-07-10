class ApplicationJob < ActiveJob::Base
  include CooperativeJob

  retry_on ActiveRecord::Deadlocked, wait: :exponentially_longer, attempts: 3
  retry_on ActiveRecord::StaleObjectError, wait: :exponentially_longer, attempts: 3 do |job, error|
    Rails.logger.error(
      event: "job_retry_exhausted",
      job_class: job.class.name,
      error: error.class.name,
      error_message: error.message,
      request_id: Current.request_id
    )
  end

  around_perform do |job, block|
    request_id = Current.request_id || SecureRandom.uuid
    Current.request_id = request_id
    block.call
  end

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
