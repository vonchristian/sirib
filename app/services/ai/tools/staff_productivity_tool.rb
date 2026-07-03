module Ai
  module Tools
    class StaffProductivityTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        today = Date.current
        staff = User.joins(:role_assignments)
          .where(management_role_assignments: { branch_id: @branch.id })

        total_staff = staff.count

        staff_activity = staff.map { |user|
          loans_processed = Lending::LoanEvent.where(
            actor: user,
            created_at: today.all_day
          ).count

          {
            user_id: user.id,
            name: user.name,
            email: user.email_address,
            role_names: user.role_assignments.active.map { |ra| ra.role.name }.uniq,
            loans_processed_today: loans_processed,
            last_login_at: user.last_login_at
          }
        }

        active_today = staff_activity.count { |s| s[:loans_processed_today] > 0 }
        inactive_staff = staff_activity.select { |s| s[:loans_processed_today] == 0 }

        {
          total_staff: total_staff,
          active_today_count: active_today,
          inactive_today_count: inactive_staff.count,
          staff_activity: staff_activity,
          total_loan_events_today: staff_activity.sum { |s| s[:loans_processed_today] }
        }
      end
    end
  end
end
