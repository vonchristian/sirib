module Ai
  module Tools
    class BranchMetricsTool
      def self.call(branch:)
        new(branch).call
      end

      def initialize(branch)
        @branch = branch
      end

      def call
        today = Date.current
        yesterday = today - 1.day

        loans_released_yesterday = Lending::Loan.where(disbursed_at: yesterday.all_day, member: members)
        payments_yesterday = Lending::LoanPayment.where(payment_date: yesterday, loan: Lending::Loan.where(member: members))

        new_members_yesterday = Membership::Member.where(branch_id: @branch.id, created_at: yesterday.all_day)

        pending_applications = Lending::LoanApplication.where(status: %w[submitted verified], member: members)
        pending_approvals = Management::ApprovalRequest.pending.where(branch: @branch)

        total_savings = Treasury::SavingsAccount.active.where(depositor: members).sum { |a| a.liability_account&.balance&.cents.to_i }

        {
          branch_name: @branch.name,
          date: today.to_s,
          loans_released_count: loans_released_yesterday.count,
          loans_released_amount_cents: loans_released_yesterday.sum(:principal_cents).to_i,
          collections_count: payments_yesterday.count,
          collections_amount_cents: payments_yesterday.sum(:amount_cents).to_i,
          new_members_count: new_members_yesterday.count,
          pending_applications_count: pending_applications.count,
          pending_approvals_count: pending_approvals.count,
          total_savings_cents: total_savings
        }
      end

      private

      def members
        Membership::Member.where(branch_id: @branch.id)
      end
    end
  end
end
