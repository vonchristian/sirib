module Management
  class SettingsController < BaseController
    before_action -> { require_permission!(action: :configure, subject: :system) }

    def index
      @configurations = Management::Configuration.where(configurable: nil).order(:key)
    end
  end
end
