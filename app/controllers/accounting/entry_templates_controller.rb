module Accounting
  class EntryTemplatesController < FinancialBaseController
    def index
      @templates = Accounting::EntryTemplate.by_cooperative(Current.cooperative).active.order(:name)
      @pagy, @templates = pagy(@templates)
    end
  end
end
