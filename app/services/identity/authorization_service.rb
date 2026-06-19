module Identity
  class AuthorizationService
    DENY = :deny
    ALLOW = :allow
    NEUTRAL = :neutral

    def self.can?(employee:, action:, subject:, branch: nil)
      new(employee: employee).can?(action: action, subject: subject, branch: branch)
    end

    def initialize(employee:)
      @employee = employee
    end

    def can?(action:, subject:, branch: nil)
      return false unless @employee&.status_active?

      override = check_overrides(action, subject)
      return override == ALLOW if override != NEUTRAL

      check_permissions(action, subject, branch)
    end

    private

    def check_overrides(action, subject)
      result = @employee.permission_overrides_for(action, subject)
      return NEUTRAL if result.nil?

      result == "deny" ? DENY : ALLOW
    end

    def check_permissions(action, subject, branch)
      scope = @employee.role_assignments.active

      if branch
        in_branch = scope.where(branch: branch)
                          .joins(role: { role_permissions: :permission })
                          .where(management_permissions: { action: action, subject: subject })
                          .exists?
        return true if in_branch
      end

      scope.joins(role: { role_permissions: :permission })
           .where(management_permissions: { action: action, subject: subject })
           .exists?
    end
  end
end
