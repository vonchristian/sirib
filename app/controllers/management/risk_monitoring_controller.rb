module Management
  class RiskMonitoringController < BaseController
    def index
      @risk_indicators = Management::RiskIndicator.where(as_of_date: Date.current).order(:indicator_type)
      @critical_count = @risk_indicators.critical.count
      @elevated_count = @risk_indicators.elevated.count
      @normal_count = @risk_indicators.normal.count
    end
  end
end
