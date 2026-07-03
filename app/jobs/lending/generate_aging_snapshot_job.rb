module Lending
  class GenerateAgingSnapshotJob < ApplicationJob
    queue_as :default

    def perform(snapshot_date: Date.current)
      Lending::AgingCalculationService.refresh_all(as_of: snapshot_date)

      Cooperative.find_each do |cooperative|
        Current.set(cooperative: cooperative) do
          Lending::LoanAgingGroup.active.ordered.each do |group|
            agings = Lending::LoanAging
              .joins(:loan)
              .where(
                loan_aging_group_id: group.id,
                loans: { status: "active", cooperative_id: cooperative.id }
              )

            snapshot = Lending::LoanAgingSnapshot.find_or_initialize_by(
              cooperative: cooperative,
              loan_aging_group: group,
              snapshot_date: snapshot_date
            )

            snapshot.update!(
              loan_count: agings.count,
              member_count: agings.joins(:loan).select(:member_id).distinct.count,
              principal_amount_cents: agings.sum(:outstanding_principal_cents),
              interest_amount_cents: agings.sum(:outstanding_interest_cents),
              total_exposure_cents: agings.sum(:total_exposure_cents)
            )
          end
        end
      end
    end
  end
end
