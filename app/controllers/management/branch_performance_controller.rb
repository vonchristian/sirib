module Management
  class BranchPerformanceController < BaseController
    def index
      @branches = Management::Branch.active.by_name.map do |branch|
        snap = branch.performance_snapshots.order(snapshot_date: :desc).first
        metrics = snap&.metrics || {}
        prev_snap = branch.performance_snapshots.order(snapshot_date: :desc).offset(1).first
        prev_metrics = prev_snap&.metrics || {}
        prev_portfolio = prev_metrics["loan_portfolio_cents"].to_f
        current_portfolio = metrics["loan_portfolio_cents"].to_f
        growth = prev_portfolio > 0 ? ((current_portfolio - prev_portfolio) / prev_portfolio * 100).round(1) : 0
        {
          branch: branch,
          snapshot: snap,
          total_assets: Money.new(metrics["loan_portfolio_cents"] || 0, "PHP"),
          loan_portfolio: Money.new(metrics["loan_portfolio_cents"] || 0, "PHP"),
          savings_deposits: Money.new(metrics["savings_balance_cents"] || 0, "PHP"),
          member_count: metrics["total_members"] || 0,
          growth_rate: growth
        }
      end.sort_by { |b| -b[:total_assets].cents }
    end
  end
end
