require Rails.root.join("lib/correlation_id")
Rails.application.config.middleware.use CorrelationId
