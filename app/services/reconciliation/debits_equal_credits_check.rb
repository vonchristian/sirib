module Reconciliation
  class DebitsEqualCreditsCheck < BaseCheck
    private

    def run_check
      failures = []
      scope = Accounting::Entry.where(status: "posted").where("posted_at >= ?", as_of_date.beginning_of_day)
      scope = scope.where(cooperative: cooperative) if cooperative

      scope.find_each(batch_size: 100) do |entry|
        debits = entry.amount_lines.select(&:debit?).sum(&:amount_cents)
        credits = entry.amount_lines.select(&:credit?).sum(&:amount_cents)
        if debits != credits
          failures << {
            resource_type: "Accounting::Entry",
            resource_id: entry.id,
            reference_number: entry.reference_number,
            expected: credits,
            actual: debits,
            diff: debits - credits
          }
        end
      end
      failures
    end

    def total_count
      scope = Accounting::Entry.where(status: "posted")
      scope = scope.where(cooperative: cooperative) if cooperative
      scope.count
    end
  end
end
