module Accounting
  class EntryTemplatesController < ApplicationController
    layout "shell"

    def index
      @templates = Accounting::EntryTemplate.active.order(:name)
      @pagy, @templates = pagy(@templates)
    end
  end
end
