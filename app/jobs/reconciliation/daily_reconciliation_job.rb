module Reconciliation
  class DailyReconciliationJob < ApplicationJob
    queue_as :default

    def perform
      Cooperative.find_each do |cooperative|
        checks.each do |check_class|
          check_class.run!(cooperative: cooperative, as_of_date: Date.yesterday)
        end
      end
    end

    private

    def checks
      [
        Reconciliation::DebitsEqualCreditsCheck,
        Reconciliation::RunningBalanceAccuracyCheck,
        Reconciliation::LoanPrincipalIntegrityCheck,
        Reconciliation::PaymentAllocationCheck,
        Reconciliation::EntryStatusCheck
      ]
    end
  end
end
