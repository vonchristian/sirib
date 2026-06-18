module Management
  class SettingsController < BaseController
    def index
      @configurations = Management::Configuration.where(configurable: nil).order(:key)
    end
  end
end
