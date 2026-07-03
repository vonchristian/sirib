module Lending
  class LoanAgingController < ApplicationController
    layout "shell"

    def index
      @filters = extract_filters
      @dashboard = AgingDashboardData.new(filters: @filters)
      @summary = @dashboard.summary
      @aging_distribution = @dashboard.aging_distribution
      @branch_performance = @dashboard.branch_performance
      @pagy, @delinquent_loans = pagy(@dashboard.delinquent_loans, limit: 25)

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("summary_cards", partial: "lending/loan_aging/summary_cards"),
            turbo_stream.replace("aging_distribution", partial: "lending/loan_aging/aging_distribution"),
            turbo_stream.replace("branch_performance", partial: "lending/loan_aging/branch_performance"),
            turbo_stream.replace("delinquent_loans", partial: "lending/loan_aging/delinquent_loans"),
            turbo_stream.replace("filters", partial: "lending/loan_aging/filters")
          ]
        end
      end
    end

    private

    def extract_filters
      permitted = params.permit(:branch_id, :loan_product_id, :loan_aging_group_id, :min_dpd, :max_dpd, :as_of_date)
      permitted.to_h.symbolize_keys
    end
  end
end
