module Accounting
  class CashFlowController < ApplicationController
    layout "shell"

    def index
      @to_date = parse_date(params[:to_date]) || Date.current
      @from_date = parse_date(params[:from_date]) || @to_date.beginning_of_month

      result = Accounting::CashFlowStatement.run!(
        from_date: @from_date,
        to_date: @to_date,
        user: Current.session.user
      )

      @report = result[:sections]
      @net_change = result[:net_change]
      @cash_at_beginning = result[:cash_at_beginning]
      @cash_at_end = result[:cash_at_end]
    end

    private

    def parse_date(str)
      Date.parse(str)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
