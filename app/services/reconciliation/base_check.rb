module Reconciliation
  class BaseCheck < ActiveInteraction::Base
    object :cooperative, class: Cooperative, default: nil
    date :as_of_date, default: -> { Date.current }

    def execute
      failures = run_check
      record_result(failures)
      alert_if_needed(failures)
      failures
    end

    private

    def check_name
      self.class.name.demodulize
    end

    def run_check
      raise NotImplementedError
    end

    def record_result(failures)
      Reconciliation::Result.create!(
        check_name: check_name,
        status: failures.empty? ? :passed : :failed,
        total_checked: total_count,
        failures_count: failures.size,
        failures: failures.first(100),
        cooperative: cooperative || Current.cooperative,
        checked_at: Time.current
      )
    end

    def alert_if_needed(failures)
      return if failures.empty?

      Management::Alert.create!(
        alert_type: "reconciliation_failure",
        severity: "critical",
        title: "Reconciliation failure: #{check_name}",
        message: "#{failures.size} failures detected as of #{as_of_date}",
        source: "Reconciliation::#{check_name}",
        status: "active",
        cooperative: cooperative || Current.cooperative
      )
    end

    def total_count
      0
    end
  end
end
