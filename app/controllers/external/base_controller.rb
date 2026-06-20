module External
  class BaseController < ApplicationController
    layout "shell"

    private

    def set_active_nav
      @active_nav = "external_banking"
    end
  end
end