module Ai
  module Tools
    class PortfolioRiskTool
      def self.call(branch:, compare_previous: true)
        new(branch, compare_previous).call
      end

      def initialize(branch, compare_previous = true)
        @branch = branch
        @compare_previous = compare_previous
      end

      def call
        member_ids = members.select(:id)
        loans = Lending::Loan.where(member_id: member_ids)

        total_portfolio_cents = loans.active.sum(:outstanding_principal_cents).to_i
        total_loans_count = loans.active.count

        agings = Lending::LoanAging.joins(:loan).where(loans: { member_id: member_ids })

        par_buckets = {
          par1: agings.where("days_past_due >= 1").sum(:total_exposure_cents).to_i,
          par7: agings.where("days_past_due >= 7").sum(:total_exposure_cents).to_i,
          par30: agings.where("days_past_due >= 30").sum(:total_exposure_cents).to_i,
          par60: agings.where("days_past_due >= 60").sum(:total_exposure_cents).to_i,
          par90: agings.where("days_past_due >= 90").sum(:total_exposure_cents).to_i
        }

        par_rates = {}
        par_buckets.each do |key, cents|
          par_rates[key] = total_portfolio_cents > 0 ? (cents.to_f / total_portfolio_cents * 100).round(2) : 0
        end

        restructured = loans.where(status: %w[refinanced modified hybrid_restructured])
        defaulted = loans.where(status: "defaulted")
        written_off = loans.where(status: "written_off")

        if @compare_previous
          previous_agings = Lending::LoanAgingSnapshot.where(
            snapshot_date: 7.days.ago.to_date
          ).joins(:loan_aging_group)
          previous_par30 = previous_agings
            .where(loan_aging_groups: { min_days: 30.. })
            .sum(:total_exposure_cents).to_i
          previous_portfolio = total_portfolio_cents > 0 ? (previous_par30.to_f / [ total_portfolio_cents, 1 ].max * 100).round(2) : 0
          par_change = par_rates[:par30] - previous_portfolio
        else
          previous_portfolio = 0
          par_change = 0
        end

        {
          total_portfolio_cents: total_portfolio_cents,
          total_active_loans: total_loans_count,
          par1_rate: par_rates[:par1],
          par7_rate: par_rates[:par7],
          par30_rate: par_rates[:par30],
          par60_rate: par_rates[:par60],
          par90_rate: par_rates[:par90],
          par30_change_from_last_week: par_change.round(2),
          restructured_count: restructured.count,
          restructured_amount_cents: restructured.sum(:outstanding_principal_cents).to_i,
          defaulted_count: defaulted.count,
          defaulted_amount_cents: defaulted.sum(:outstanding_principal_cents).to_i,
          written_off_count: written_off.count,
          written_off_amount_cents: written_off.sum(:outstanding_principal_cents).to_i
        }
      end

      private

      def members
        Membership::Member.where(branch_id: @branch.id)
      end
    end
  end
end
