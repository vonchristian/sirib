module Ai
  module Tools
    class MembershipTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        members = Membership::Member.where(branch_id: @branch.id)
        total_members = members.count

        this_month = members.where(created_at: Date.current.beginning_of_month..)
        last_month = members.where(created_at: (Date.current - 1.month).beginning_of_month..(Date.current - 1.month).end_of_month)

        growth = last_month.count > 0 ? (((this_month.count - last_month.count).to_f / last_month.count) * 100).round(1) : 0

        portal_active = members.portal_active.count
        portal_inactive = members.where(portal_status: "inactive").count

        incomplete_apps = Lending::LoanApplication.where(status: "draft", member: members)
        submitted_apps = Lending::LoanApplication.where(status: "submitted", member: members)

        {
          total_members: total_members,
          new_members_this_month: this_month.count,
          new_members_last_month: last_month.count,
          membership_growth_pct: growth,
          portal_active_count: portal_active,
          portal_inactive_count: portal_inactive,
          incomplete_applications: incomplete_apps.count,
          pending_applications: submitted_apps.count
        }
      end
    end
  end
end
