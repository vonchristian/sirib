module Ai
  module Tools
    class CollectionsTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        today = Date.current
        member_ids = members.select(:id)

        loans_due_today = Lending::LoanSchedule.joins(loan: :member)
          .where(loans: { member_id: member_ids, status: "active" })
          .where(due_date: today)

        overdue_loans = Lending::LoanAging.joins(:loan)
          .where(loans: { member_id: member_ids })
          .where("days_past_due > 0")
          .order(days_past_due: :desc)

        par30_entries = overdue_loans.where("days_past_due >= 30")
        par60_entries = overdue_loans.where("days_past_due >= 60")

        payments_this_month = Lending::LoanPayment.where(
          payment_date: today.beginning_of_month..today,
          loan: Lending::Loan.where(member_id: member_ids)
        )

        scheduled_this_month = Lending::LoanSchedule.joins(loan: :member)
          .where(loans: { member_id: member_ids, status: "active" })
          .where(due_date: today.beginning_of_month..today)

        target_cents = scheduled_this_month.sum(:principal_cents) + scheduled_this_month.sum(:interest_cents)
        collected_cents = payments_this_month.sum(:amount_cents).to_i
        efficiency = target_cents > 0 ? (collected_cents.to_f / target_cents * 100).round(1) : 0

        {
          loans_due_today_count: loans_due_today.count,
          loans_due_today_amount_cents: (loans_due_today.sum(:principal_cents) + loans_due_today.sum(:interest_cents)).to_i,
          overdue_loans_count: overdue_loans.count,
          overdue_loans_total_exposure_cents: overdue_loans.sum(:total_exposure_cents).to_i,
          par30_count: par30_entries.count,
          par30_exposure_cents: par30_entries.sum(:total_exposure_cents).to_i,
          par60_count: par60_entries.count,
          par60_exposure_cents: par60_entries.sum(:total_exposure_cents).to_i,
          collection_target_cents: target_cents,
          collection_collected_cents: collected_cents,
          collection_efficiency_pct: efficiency
        }
      end

      private

      def members
        Membership::Member.where(branch_id: @branch.id)
      end
    end
  end
end
