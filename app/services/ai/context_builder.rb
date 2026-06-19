module Ai
  class ContextBuilder
    def self.build(user:, cash_session: nil, current_route: "/", params: {})
      new(user:, cash_session:, current_route:, params:).build
    end

    def initialize(user:, cash_session: nil, current_route: "/", params: {})
      @user = user
      @cash_session = cash_session
      @current_route = current_route
      @params = params
    end

    def build
      {
        user_role: @user&.role || "unknown",
        user_name: @user&.name,
        current_route: @current_route,
        selected_entity: selected_entity,
        cash_session_id: @cash_session&.id,
        cash_session_status: @cash_session&.status,
        branch: Current.branch&.name,
        timestamp: Time.current.iso8601,
        environment: Rails.env
      }
    end

    private

    def selected_entity
      return nil if @params[:entity_type].blank? || @params[:entity_id].blank?

      {
        type: @params[:entity_type],
        id: @params[:entity_id].to_i
      }
    end
  end
end
