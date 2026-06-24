module Accounting
  class TrialBalanceController < ApplicationController
    layout "shell"

    def index
      @as_of_date = parse_date(params[:as_of_date]) || Date.current
      @result = Accounting::TrialBalanceService.run!(as_of: @as_of_date, cooperative: Current.cooperative)
    end

    private

    def parse_date(str)
      Date.parse(str)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
