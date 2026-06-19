module Identity
  class ContextResolver
    IDLE_TIMEOUT = 30.minutes
    SESSION_MAX_AGE = 8.hours

    def self.resolve(employee:)
      new(employee).resolve
    end

    def initialize(employee)
      @employee = employee
    end

    def resolve
      {
        employee: @employee,
        status: @employee.status,
        status_active: @employee.status_active?,
        roles: effective_roles,
        permissions: effective_permissions,
        branch_scope: branch_scope,
        overrides: @employee.permission_overrides || {},
        session_valid: false
      }
    end

    def resolve_with_session(session:)
      base = resolve
      base.merge(
        session_valid: session_valid?(session),
        session: session
      )
    end

    def effective_roles
      @employee.role_assignments.active.includes(:role).map(&:role)
    end

    def effective_permissions
      PermissionMatrix.new(@employee)
    end

    def branch_scope
      @employee.role_assignments.active.includes(:branch).map(&:branch).compact.uniq
    end

    def session_valid?(session)
      return false unless session
      return false if session.revoked_at.present?
      return false if session.last_activity_at.present? && session.last_activity_at < IDLE_TIMEOUT.ago
      return false if session.created_at < SESSION_MAX_AGE.ago

      true
    end

    def touch_session!(session)
      return unless session
      return unless session.last_activity_at.nil? || session.last_activity_at < 5.minutes.ago

      session.touch_activity!
    end

    class PermissionMatrix
      def initialize(employee)
        @employee = employee
        @cache = nil
      end

      def entries
        @cache ||= build_entries
      end

      def can?(action, subject, branch: nil)
        AuthorizationService.can?(
          employee: @employee,
          action: action,
          subject: subject,
          branch: branch
        )
      end

      private

      def build_entries
        @employee.role_assignments.active
          .joins(role: { role_permissions: :permission })
          .pluck(
            Arel.sql("DISTINCT management_permissions.action, management_permissions.subject, management_role_assignments.branch_id")
          )
          .map { |action, subject, branch_id|
            { action: action, subject: subject, branch_id: branch_id }
          }
      end
    end
  end
end
