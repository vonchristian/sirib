module Management
  class AlertsController < BaseController
    before_action :set_alert, only: [:show, :resolve]

    def index
      @alerts = Management::Alert.by_severity
      @alerts = @alerts.where(alert_type: params[:type]) if params[:type].present?
      @alerts = @alerts.where(status: params[:status]) if params[:status].present?
      @pagy, @alerts = pagy(@alerts)
    end

    def show
    end

    def resolve
      @alert.resolve!(Current.user)
      redirect_to management_alerts_path, notice: "Alert was resolved."
    end

    private

    def set_alert
      @alert = Management::Alert.find(params[:id])
    end
  end
end
