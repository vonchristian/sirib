module BusinessEventLogger
  def self.log(service:, action:, resource:, metadata: {})
    Rails.logger.info(
      event: "business",
      service: service,
      action: action,
      resource_type: resource.class.name,
      resource_id: resource.id,
      cooperative_id: Current.cooperative&.id,
      user_id: Current.user&.id,
      request_id: Current.request_id,
      metadata: metadata
    )
  rescue => e
    Rails.logger.error(
      event: "business_logging_error",
      message: "Failed to log business event",
      error: e.class.name,
      error_message: e.message,
      service: service,
      action: action
    )
  end
end
