Rails.application.reloader.to_prepare do
  ActiveSupport::Notifications.subscribe("security.login.success") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.info "[SECURITY] Login success: user_id=#{event.payload[:user_id]} ip=#{event.payload[:ip]}"
  end

  ActiveSupport::Notifications.subscribe("security.login.failure") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    Rails.logger.warn "[SECURITY] Login failure: user_id=#{event.payload[:user_id]} ip=#{event.payload[:ip]}"
  end
end
