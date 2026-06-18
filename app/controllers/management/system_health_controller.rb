module Management
  class SystemHealthController < BaseController
    def index
      @latest_snapshot = Management::SystemHealthSnapshot.order(captured_at: :desc).first
      @recent_snapshots = Management::SystemHealthSnapshot.order(captured_at: :desc).limit(20)
      @healthy_count = Management::SystemHealthSnapshot.where(captured_at: 24.hours.ago..Time.current, status: :healthy).count
      @warning_count = Management::SystemHealthSnapshot.where(captured_at: 24.hours.ago..Time.current, status: :warning).count
      @critical_count = Management::SystemHealthSnapshot.where(captured_at: 24.hours.ago..Time.current, status: :critical).count
    end
  end
end
