module Lending
  class ApprovalWorkflowService
    def self.call(restructure_case:)
      new(restructure_case).call
    end

    def initialize(restructure_case)
      @restructure_case = restructure_case
      @loan = restructure_case.loan
    end

    def call
      levels = calculate_required_levels

      {
        required_approvals: levels,
        routing: levels.map { |level| level_info(level) }
      }
    end

    def calculate_required_levels
      levels = %w[credit_officer]

      payoff = LoanPayoffService.call(loan: @loan)
      threshold = current_threshold

      levels << "branch_manager" if payoff[:total_payoff_cents] > threshold[:branch_manager]
      levels << "credit_committee" if payoff[:total_payoff_cents] > threshold[:credit_committee]

      levels
    end

    private

    def current_threshold
      thresholds = Management::Configuration.where(key: %w[
        restructure_branch_manager_threshold_cents
        restructure_credit_committee_threshold_cents
      ]).pluck(:key, :value).to_h

      {
        branch_manager: (thresholds["restructure_branch_manager_threshold_cents"] || 500_00).to_i,
        credit_committee: (thresholds["restructure_credit_committee_threshold_cents"] || 2_000_00).to_i
      }
    end

    def level_info(level)
      case level
      when "credit_officer"
        { name: "Credit Officer", description: "Initial review and recommendation" }
      when "branch_manager"
        { name: "Branch Manager", description: "Approval for restructures above branch threshold" }
      when "credit_committee"
        { name: "Credit Committee", description: "Final approval for high-value restructures" }
      end
    end
  end
end
