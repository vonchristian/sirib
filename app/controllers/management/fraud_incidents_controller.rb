module Management
  class FraudIncidentsController < BaseController
    before_action :require_permission!, only: :resolve, action: :resolve, subject: :fraud_incident

    def index
      @incidents = Fraud::Incident.by_cooperative(Current.cooperative)
        .includes(:rule, :actor)
        .by_severity
        .by_recent

      @pagy, @incidents = pagy(@incidents)
    end

    def show
      @incident = Fraud::Incident.by_cooperative(Current.cooperative)
        .includes(:rule, :actor, :resolved_by)
        .find(params[:id])
    end

    def resolve
      @incident = Fraud::Incident.by_cooperative(Current.cooperative).find(params[:id])

      if @incident.resolve!(user: Current.user, resolution: params[:resolution])
        redirect_to management_fraud_incident_path(@incident), notice: "Incident resolved."
      else
        redirect_to management_fraud_incident_path(@incident), alert: "Could not resolve incident."
      end
    end
  end
end
