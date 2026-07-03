module Lending
  class AgingDashboardData
    attr_reader :filters

    def initialize(filters: {})
      @filters = filters
    end

    def summary
      {
        total_portfolio_cents: total_portfolio_cents,
        delinquent_portfolio_cents: delinquent_portfolio_cents,
        par30_cents: par_amount(30),
        par60_cents: par_amount(60),
        par90_cents: par_amount(90),
        par30_ratio: par_ratio(30),
        par60_ratio: par_ratio(60),
        par90_ratio: par_ratio(90),
        delinquent_loan_count: delinquent_loan_count,
        delinquent_member_count: delinquent_member_count
      }
    end

    def aging_distribution
      Lending::LoanAgingGroup.active.ordered.map do |group|
        agings = base_scope.where(loan_aging_group_id: group.id)
        {
          group: group,
          total_exposure_cents: agings.sum(:total_exposure_cents),
          loan_count: agings.count
        }
      end
    end

    def branch_performance
      Lending::Loan.active
        .joins(:member)
        .joins("LEFT JOIN management_branches ON management_branches.id = members.branch_id")
        .joins("LEFT JOIN loan_agings ON loan_agings.loan_id = loans.id")
        .joins("LEFT JOIN loan_aging_groups ON loan_aging_groups.id = loan_agings.loan_aging_group_id")
        .select(
          "COALESCE(members.branch_id, 0) as branch_id",
          "COALESCE(management_branches.name, 'Unknown') as branch_name",
          "COUNT(DISTINCT loans.id) as portfolio_count",
          "SUM(loans.outstanding_principal_cents) as portfolio_cents",
          "COUNT(DISTINCT CASE WHEN loan_aging_groups.min_days > 0 THEN loans.id END) as delinquent_count",
          "SUM(CASE WHEN loan_aging_groups.min_days > 0 THEN loans.outstanding_principal_cents ELSE 0 END) as delinquent_cents",
          "SUM(CASE WHEN loan_aging_groups.min_days >= 30 THEN loans.outstanding_principal_cents ELSE 0 END) as par30_cents"
        )
        .group("members.branch_id, management_branches.name")
        .order(Arel.sql("delinquent_cents DESC NULLS LAST"))
        .map do |row|
          {
            branch_id: row.branch_id,
            branch_name: row.branch_name,
            portfolio_count: row.portfolio_count,
            portfolio_cents: row.portfolio_cents.to_i,
            delinquent_count: row.delinquent_count,
            delinquent_cents: row.delinquent_cents.to_i,
            par30_cents: row.par30_cents.to_i,
            par30_ratio: row.portfolio_cents.to_i > 0 ? (row.par30_cents.to_f / row.portfolio_cents.to_f * 100).round(2) : 0
          }
        end
    end

    def delinquent_loans
      base_scope
        .delinquent
        .includes(:loan, :loan_aging_group)
        .joins(loan: :member)
        .order(days_past_due: :desc)
    end

    private

    def base_scope
      scope = Lending::LoanAging.joins(:loan).where(loans: { status: "active" })

      if filters[:branch_id].present?
        scope = scope.joins(loan: :member).where(members: { branch_id: filters[:branch_id] })
      end

      if filters[:loan_product_id].present?
        scope = scope.where(loans: { loan_product_id: filters[:loan_product_id] })
      end

      if filters[:loan_aging_group_id].present?
        scope = scope.where(loan_aging_group_id: filters[:loan_aging_group_id])
      end

      if filters[:min_dpd].present? || filters[:max_dpd].present?
        scope = scope.where("days_past_due >= ?", filters[:min_dpd].to_i) if filters[:min_dpd].present?
        scope = scope.where("days_past_due <= ?", filters[:max_dpd].to_i) if filters[:max_dpd].present?
      end

      scope
    end

    def total_portfolio_cents
      Lending::Loan.active.sum(:outstanding_principal_cents)
    end

    def delinquent_portfolio_cents
      Lending::LoanAging.delinquent
        .joins(:loan)
        .where(loans: { status: "active" })
        .sum(:total_exposure_cents)
    end

    def par_amount(dpd_threshold)
      Lending::LoanAging
        .joins(:loan)
        .where(loans: { status: "active" })
        .where("days_past_due > ?", dpd_threshold)
        .sum(:total_exposure_cents)
    end

    def par_ratio(dpd_threshold)
      total = total_portfolio_cents
      return 0 if total.zero?
      (par_amount(dpd_threshold).to_f / total.to_f * 100).round(2)
    end

    def delinquent_loan_count
      Lending::LoanAging.delinquent
        .joins(:loan)
        .where(loans: { status: "active" })
        .count
    end

    def delinquent_member_count
      Lending::LoanAging.delinquent
        .joins(loan: :member)
        .where(loans: { status: "active" })
        .select(:member_id)
        .distinct
        .count
    end
  end
end
