module Management
  class RiskMonitoringService < ActiveInteraction::Base
    date :as_of_date, default: -> { Date.current }

    def execute
      indicators = []

      delinquency = compute_delinquency_rate
      indicators << record_indicator("credit_risk_delinquency", delinquency, 5.0, 10.0)
      create_alert_for("credit_risk", delinquency, 5.0, 10.0)

      liquidity = compute_liquidity_ratio
      indicators << record_indicator("liquidity_ratio", liquidity, 0.2, 0.1)

      par = compute_par
      indicators << record_indicator("portfolio_at_risk", par, 5.0, 10.0)
      create_alert_for("portfolio_at_risk", par, 5.0, 10.0)

      indicators
    end

    private

    def record_indicator(type, value, warning_threshold, critical_threshold)
      status = if value >= critical_threshold
        "critical"
      elsif value >= warning_threshold
        "elevated"
      else
        "normal"
      end

      Management::RiskIndicator.create!(
        indicator_type: type,
        value: value,
        threshold: critical_threshold,
        status: status,
        as_of_date: as_of_date
      )
    end

    def create_alert_for(type, value, warning, critical)
      if value >= critical
        Management::AlertService.run!(
          alert_type: type,
          severity: "critical",
          title: "#{type.humanize} exceeded critical threshold",
          message: "Current value: #{value.round(2)} (threshold: #{critical})",
          source: "risk_monitoring"
        )
      elsif value >= warning
        Management::AlertService.run!(
          alert_type: type,
          severity: "warning",
          title: "#{type.humanize} exceeded warning threshold",
          message: "Current value: #{value.round(2)} (threshold: #{warning})",
          source: "risk_monitoring"
        )
      end
    end

    def compute_delinquency_rate
      total = Lending::Loan.active.count
      return 0 if total.zero?
      delinquent = Lending::Loan.active.where(status: "defaulted").count
      (delinquent.to_f / total * 100).round(2)
    end

    def compute_liquidity_ratio
      cash = Accounting::Account.joins(:ledger)
        .where(ledgers: { account_type: "asset", name: "Cash on Hand" })
        .sum(:balance_cents).to_f
      liabilities = Accounting::Account.joins(:ledger)
        .where(ledgers: { account_type: "liability" })
        .sum(:balance_cents).to_f
      return 1.0 if liabilities.zero?
      (cash / liabilities).round(4)
    end

    def compute_par
      total_portfolio = Lending::Loan.active.sum(:outstanding_principal_cents).to_f
      return 0 if total_portfolio.zero?
      at_risk = Lending::Loan.active.where("updated_at < ?", 30.days.ago).sum(:outstanding_principal_cents).to_f
      ((at_risk / total_portfolio) * 100).round(2)
    end
  end
end
