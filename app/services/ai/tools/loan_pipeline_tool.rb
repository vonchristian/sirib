module Ai
  module Tools
    class LoanPipelineTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        member_ids = members.select(:id)

        pending_review = Lending::LoanApplication.where(status: "submitted", member_id: member_ids)
        pending_approval = Lending::LoanApplication.where(status: "verified", member_id: member_ids)
        pending_release = Lending::LoanApplication.where(status: "approved", member_id: member_ids)
        drafts = Lending::LoanApplication.where(status: "draft", member_id: member_ids)
        rejected = Lending::LoanApplication.where(status: "rejected", member_id: member_ids)

        sla_violations = pending_review.or(pending_approval).where("submitted_at <= ?", 48.hours.ago)

        {
          pending_review_count: pending_review.count,
          pending_approval_count: pending_approval.count,
          pending_release_count: pending_release.count,
          draft_count: drafts.count,
          rejected_count: rejected.count,
          total_in_pipeline: pending_review.count + pending_approval.count + pending_release.count,
          sla_violations_count: sla_violations.count,
          average_pending_hours: calculate_average_pending_hours(pending_review, pending_approval)
        }
      end

      private

      def members
        Membership::Member.where(branch_id: @branch.id)
      end

      def calculate_average_pending_hours(*scopes)
        apps = scopes.flat_map { |s| s.to_a }
        return 0 if apps.empty?

        hours = apps.sum { |a| ((Time.current - a.submitted_at) / 3600).round(1) }
        (hours / apps.size).round(1)
      end
    end
  end
end
