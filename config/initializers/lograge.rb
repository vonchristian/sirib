Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.keep_original_rails_log = false
  config.lograge.logger = ActiveSupport::TaggedLogging.logger(STDOUT)

  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:request_id] || event.payload[:headers]&.env&.dig("action_dispatch.request_id"),
      user_id: event.payload[:user_id] || Current.user&.id,
      cooperative_id: Current.cooperative&.id,
      ip: event.payload[:ip] || event.payload[:headers]&.env&.dig("action_dispatch.remote_ip"),
      user_agent: event.payload[:user_agent] || event.payload[:headers]&.env&.dig("HTTP_USER_AGENT"),
      params: event.payload[:params]&.except("controller", "action", "format", "authenticity_token")
    }.compact
  end

  config.lograge.ignore_actions = [ "Rails::HealthController#show" ]
  config.lograge.base_controller_class = [ "ActionController::Base" ]
end
