module Reconciliation
  class EntryStatusCheck < BaseCheck
    private

    def run_check
      failures = []
      scope = Accounting::Entry.where(status: :reversed)
      scope = scope.where(cooperative: cooperative) if cooperative

      scope.find_each(batch_size: 100) do |entry|
        if entry.reversed_at.blank?
          failures << {
            resource_type: "Accounting::Entry",
            resource_id: entry.id,
            reference_number: entry.reference_number,
            expected: "reversed_at present",
            actual: "reversed_at is nil",
            posted_at: entry.posted_at
          }
        end
      end
      failures
    end

    def total_count
      scope = Accounting::Entry.where(status: :reversed)
      scope = scope.where(cooperative: cooperative) if cooperative
      scope.count
    end
  end
end
