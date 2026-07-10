module Reporting
  class RefreshMaterializedViewsJob < ApplicationJob
    queue_as :default

    def perform
      connection = ActiveRecord::Base.connection
      connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_trial_balances")
      connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_balance_sheets")
      connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_loan_agings")
    end
  end
end