module Management
  class AuditLogsController < BaseController
    def index
      @audit_logs = Management::AuditLog.by_recent.includes(:actor)
      @audit_logs = @audit_logs.by_action(params[:action_type]) if params[:action_type].present?
      @audit_logs = @audit_logs.by_actor(params[:actor_id]) if params[:actor_id].present?
      @audit_logs = @audit_logs.where("created_at >= ?", params[:from].to_date) if params[:from].present?
      @audit_logs = @audit_logs.where("created_at <= ?", params[:to].to_date) if params[:to].present?
      @pagy, @audit_logs = pagy(@audit_logs)
    end

    def show
      @audit_log = Management::AuditLog.includes(:actor, :auditable).find(params[:id])
    end
  end
end
