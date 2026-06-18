module Management
  class PermissionService
    def self.authorized?(user:, action:, subject:, branch: nil)
      return false unless user

      user.role_assignments.active.any? do |assignment|
        role = assignment.role
        next false unless role

        if branch && assignment.branch
          next false unless assignment.branch_id == branch.id
        end

        role.permissions.any? { |p| p.action == action.to_s && p.subject == subject.to_s }
      end
    end

    def self.self_approval?(user:, record:)
      record.respond_to?(:requested_by) && record.requested_by_id == user.id
    end
  end
end
