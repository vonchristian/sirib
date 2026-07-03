module Ai
  class BranchManagerService
    SEVERITY_ORDER = { "critical" => 0, "high" => 1, "medium" => 2, "low" => 3 }.freeze

    def self.call(branch:, agent: nil, save: true)
      new(branch, agent, save).call
    end

    def initialize(branch, agent = nil, save = true)
      @branch = branch
      @agent = agent || Ai::Agent.enabled.by_name.first
      @save = save
    end

    def call
      @agent_run = create_agent_run

      metrics = collect_metrics
      observations = analyze_observations(metrics)
      recommendations = generate_recommendations(observations)
      digest = build_digest(metrics, observations, recommendations)

      if @save
        persist_results(observations, recommendations, digest)
      end

      {
        agent_run: @agent_run,
        metrics: metrics,
        observations: observations,
        recommendations: recommendations,
        digest: digest
      }
    rescue StandardError => e
      fail_agent_run(e)
      raise
    end

    private

    def create_agent_run
      return nil unless @save

      Ai::AgentRun.create!(
        agent: @agent,
        branch: @branch,
        started_at: Time.current,
        status: "running"
      )
    end

    def collect_metrics
      {
        branch_metrics: Ai::Tools::BranchMetricsTool.call(branch: @branch),
        collections: Ai::Tools::CollectionsTool.call(branch: @branch),
        loan_pipeline: Ai::Tools::LoanPipelineTool.call(branch: @branch),
        portfolio_risk: Ai::Tools::PortfolioRiskTool.call(branch: @branch),
        savings: Ai::Tools::SavingsTool.call(branch: @branch),
        membership: Ai::Tools::MembershipTool.call(branch: @branch),
        cash_position: Ai::Tools::CashPositionTool.call(branch: @branch),
        staff_productivity: Ai::Tools::StaffProductivityTool.call(branch: @branch)
      }
    end

    def analyze_observations(metrics)
      observations = []
      observations.concat(check_collection_performance(metrics[:collections]))
      observations.concat(check_loan_pipeline(metrics[:loan_pipeline]))
      observations.concat(check_portfolio_risk(metrics[:portfolio_risk]))
      observations.concat(check_savings_activity(metrics[:savings]))
      observations.concat(check_membership(metrics[:membership]))
      observations.concat(check_cash_position(metrics[:cash_position]))
      observations.concat(check_staff_productivity(metrics[:staff_productivity]))
      observations
    end

    def generate_recommendations(observations)
      observations.filter_map { |obs| build_recommendation(obs) }
    end

    def build_digest(metrics, observations, recommendations)
      branch_name = @branch.name
      today = Date.current.to_s
      bm = metrics[:branch_metrics]
      coll = metrics[:collections]
      risk = metrics[:portfolio_risk]

      summary_parts = []
      summary_parts << "Branch #{branch_name} Summary"
      summary_parts << "Date: #{today}"
      summary_parts << "Loans Released: #{bm[:loans_released_count]} (₱#{format_cents(bm[:loans_released_amount_cents])})"
      summary_parts << "Collections: ₱#{format_cents(coll[:collection_collected_cents])} / ₱#{format_cents(coll[:collection_target_cents])} (#{coll[:collection_efficiency_pct]}%)"
      summary_parts << "New Members: #{bm[:new_members_count]}"
      summary_parts << "PAR30: #{risk[:par30_rate]}%"
      summary_parts << "Pending Approvals: #{bm[:pending_approvals_count]}"

      risk_parts = []
      risk_parts << "PAR30 Rate: #{risk[:par30_rate]}% (change: #{risk[:par30_change_from_last_week]}%)"
      risk_parts << "Overdue Loans: #{coll[:overdue_loans_count]} (₱#{format_cents(coll[:overdue_loans_total_exposure_cents])})"
      risk_parts << "Defaulted Loans: #{risk[:defaulted_count]}"

      recommendation_parts = []
      recommendations.each_with_index do |rec, i|
        recommendation_parts << "#{i + 1}. [#{rec[:priority].upcase}] #{rec[:title]}"
      end

      {
        branch_name: branch_name,
        summary: summary_parts.join("\n"),
        risk_summary: risk_parts.join("\n"),
        recommendations_summary: recommendation_parts.join("\n")
      }
    end

    def persist_results(observations, recommendations, digest_data)
      saved_observations = observations.map { |obs| save_observation(obs) }

      recommendations.each_with_index do |rec, i|
        save_recommendation(rec, saved_observations[i])
      end

      Ai::Digest.create!(
        cooperative: @branch.cooperative,
        branch: @branch,
        agent_run: @agent_run,
        generated_at: Time.current,
        summary: digest_data[:summary],
        risk_summary: digest_data[:risk_summary],
        recommendations_summary: digest_data[:recommendations_summary],
        metrics: @metrics || {},
        observation_count: saved_observations.count,
        recommendation_count: recommendations.count
      )

      @agent_run.update!(
        completed_at: Time.current,
        status: "completed",
        execution_time_ms: ((Time.current - @agent_run.started_at) * 1000).to_i
      )
    end

    def save_observation(obs)
      Ai::Observation.create!(
        cooperative: @branch.cooperative,
        branch: @branch,
        agent_run: @agent_run,
        category: obs[:category],
        severity: obs[:severity],
        title: obs[:title],
        summary: obs[:summary],
        metadata: obs[:metadata] || {},
        detected_at: Time.current
      )
    end

    def save_recommendation(rec, observation)
      Ai::Recommendation.create!(
        cooperative: @branch.cooperative,
        branch: @branch,
        observation: observation,
        agent_run: @agent_run,
        priority: rec[:priority],
        title: rec[:title],
        summary: rec[:summary],
        action_text: rec[:action_text],
        confidence_score: rec[:confidence_score] || 0.85,
        status: "open"
      )
    end

    def fail_agent_run(error)
      return unless @agent_run

      @agent_run.update!(
        completed_at: Time.current,
        status: "failed",
        error_message: error.message,
        execution_time_ms: ((Time.current - @agent_run.started_at) * 1000).to_i
      )
    end

    def check_collection_performance(coll)
      observations = []

      if coll[:collection_efficiency_pct] < 80
        observations << {
          category: "collections",
          severity: "high",
          title: "Collections below 80% target",
          summary: "Collection efficiency is at #{coll[:collection_efficiency_pct]}%. Target was ₱#{format_cents(coll[:collection_target_cents])}, collected ₱#{format_cents(coll[:collection_collected_cents])}.",
          metadata: { efficiency: coll[:collection_efficiency_pct], target_cents: coll[:collection_target_cents], collected_cents: coll[:collection_collected_cents] }
        }
      end

      if coll[:overdue_loans_count] > 0
        observations << {
          category: "collections",
          severity: coll[:overdue_loans_count] > 20 ? "high" : "medium",
          title: "#{coll[:overdue_loans_count]} overdue loans require attention",
          summary: "#{coll[:overdue_loans_count]} loans are overdue with total exposure of ₱#{format_cents(coll[:overdue_loans_total_exposure_cents])}.",
          metadata: { overdue_count: coll[:overdue_loans_count], exposure_cents: coll[:overdue_loans_total_exposure_cents] }
        }
      end

      observations
    end

    def check_loan_pipeline(pipeline)
      observations = []

      if pipeline[:sla_violations_count] > 0
        observations << {
          category: "loan_pipeline",
          severity: "high",
          title: "#{pipeline[:sla_violations_count]} loan applications exceed SLA",
          summary: "#{pipeline[:sla_violations_count]} applications have been waiting more than 48 hours. Average pending time: #{pipeline[:average_pending_hours]} hours.",
          metadata: { sla_violations: pipeline[:sla_violations_count], avg_hours: pipeline[:average_pending_hours] }
        }
      end

      if pipeline[:pending_review_count] > 10
        observations << {
          category: "loan_pipeline",
          severity: "medium",
          title: "Loan application backlog: #{pipeline[:pending_review_count]} pending review",
          summary: "#{pipeline[:pending_review_count]} applications are pending initial review.",
          metadata: { pending_review: pipeline[:pending_review_count] }
        }
      end

      if pipeline[:pending_release_count] > 5
        observations << {
          category: "loan_pipeline",
          severity: "medium",
          title: "#{pipeline[:pending_release_count]} approved loans pending release",
          summary: "#{pipeline[:pending_release_count]} approved loans have not been released yet.",
          metadata: { pending_release: pipeline[:pending_release_count] }
        }
      end

      observations
    end

    def check_portfolio_risk(risk)
      observations = []

      if risk[:par30_rate] > 5
        observations << {
          category: "portfolio_risk",
          severity: risk[:par30_rate] > 10 ? "critical" : "high",
          title: "PAR30 at #{risk[:par30_rate]}%",
          summary: "Portfolio at Risk (30 days) is #{risk[:par30_rate]}%. #{(risk[:par30_change_from_last_week] > 0 ? "Increased" : "Decreased")} by #{risk[:par30_change_from_last_week].abs}% from last week.",
          metadata: { par30_rate: risk[:par30_rate], change: risk[:par30_change_from_last_week] }
        }
      end

      if risk[:defaulted_count] > 0
        observations << {
          category: "portfolio_risk",
          severity: "high",
          title: "#{risk[:defaulted_count]} defaulted loans totaling ₱#{format_cents(risk[:defaulted_amount_cents])}",
          summary: "#{risk[:defaulted_count]} loans are in default status with outstanding principal of ₱#{format_cents(risk[:defaulted_amount_cents])}.",
          metadata: { defaulted_count: risk[:defaulted_count], amount_cents: risk[:defaulted_amount_cents] }
        }
      end

      observations
    end

    def check_savings_activity(savings)
      observations = []

      if savings[:dormant_accounts_count] > savings[:total_accounts] * 0.2
        observations << {
          category: "savings",
          severity: "medium",
          title: "#{savings[:dormant_accounts_count]} dormant savings accounts",
          summary: "#{savings[:dormant_accounts_count]} out of #{savings[:total_accounts]} savings accounts have been inactive for 90+ days (#{(savings[:dormant_accounts_count].to_f / savings[:total_accounts] * 100).round(1)}%).",
          metadata: { dormant_count: savings[:dormant_accounts_count], total_accounts: savings[:total_accounts] }
        }
      end

      if savings[:net_flow_last_7d_cents] < -1_000_000_00
        observations << {
          category: "savings",
          severity: "high",
          title: "Significant savings withdrawal spike",
          summary: "Net savings outflow of ₱#{format_cents(savings[:net_flow_last_7d_cents].abs)} in the last 7 days.",
          metadata: { net_flow_cents: savings[:net_flow_last_7d_cents] }
        }
      end

      observations
    end

    def check_membership(membership)
      observations = []

      if membership[:portal_inactive_count] > membership[:total_members] * 0.5
        observations << {
          category: "membership",
          severity: "low",
          title: "#{membership[:portal_inactive_count]} members not using portal",
          summary: "#{membership[:portal_inactive_count]} out of #{membership[:total_members]} members (#{(membership[:portal_inactive_count].to_f / membership[:total_members] * 100).round(1)}%) have not activated their portal access.",
          metadata: { inactive_count: membership[:portal_inactive_count], total: membership[:total_members] }
        }
      end

      if membership[:incomplete_applications] > 10
        observations << {
          category: "membership",
          severity: "low",
          title: "#{membership[:incomplete_applications]} incomplete loan applications",
          summary: "#{membership[:incomplete_applications]} loan applications are still in draft status.",
          metadata: { incomplete: membership[:incomplete_applications] }
        }
      end

      observations
    end

    def check_cash_position(cash)
      observations = []

      if cash[:unbalanced_sessions_count] > 0
        observations << {
          category: "cash_position",
          severity: "high",
          title: "#{cash[:unbalanced_sessions_count]} unbalanced cash sessions",
          summary: "#{cash[:unbalanced_sessions_count]} teller sessions have a cash variance totaling ₱#{format_cents(cash[:total_variance_cents])}.",
          metadata: { unbalanced_count: cash[:unbalanced_sessions_count], variance_cents: cash[:total_variance_cents] }
        }
      end

      observations
    end

    def check_staff_productivity(staff)
      observations = []

      if staff[:inactive_today_count] > staff[:total_staff] * 0.3
        observations << {
          category: "staff_productivity",
          severity: "medium",
          title: "#{staff[:inactive_today_count]} staff members with no recorded activity today",
          summary: "#{staff[:inactive_today_count]} out of #{staff[:total_staff]} staff members (#{(staff[:inactive_today_count].to_f / staff[:total_staff] * 100).round(1)}%) have no recorded loan processing activity today.",
          metadata: { inactive_count: staff[:inactive_today_count], total: staff[:total_staff] }
        }
      end

      observations
    end

    def build_recommendation(obs)
      case obs[:category]
      when "collections"
        build_collection_recommendation(obs)
      when "loan_pipeline"
        build_pipeline_recommendation(obs)
      when "portfolio_risk"
        build_risk_recommendation(obs)
      when "savings"
        build_savings_recommendation(obs)
      when "membership"
        build_membership_recommendation(obs)
      when "cash_position"
        build_cash_recommendation(obs)
      when "staff_productivity"
        build_staff_recommendation(obs)
      end
    end

    def build_collection_recommendation(obs)
      if obs[:title].include?("below 80%")
        {
          priority: "high",
          title: "Improve collection efficiency",
          summary: "Collection efficiency is below 80%. Review collection routes and assign additional collectors to high-delinquency areas.",
          action_text: "Schedule a collection strategy meeting and review collector assignments for the week.",
          confidence_score: 0.85
        }
      elsif obs[:title].include?("overdue")
        {
          priority: "high",
          title: "Prioritize overdue loan collections",
          summary: "#{obs[:metadata][:overdue_count]} loans are overdue with ₱#{format_cents(obs[:metadata][:exposure_cents])} total exposure.",
          action_text: "Assign collection officers to top 10 overdue accounts by exposure for immediate follow-up.",
          confidence_score: 0.90
        }
      end
    end

    def build_pipeline_recommendation(obs)
      if obs[:title].include?("SLA")
        {
          priority: "high",
          title: "Clear SLA-violating loan applications",
          summary: "#{obs[:metadata][:sla_violations]} applications exceed 48-hour SLA.",
          action_text: "Assign pending applications to available loan officers for immediate review.",
          confidence_score: 0.88
        }
      elsif obs[:title].include?("backlog")
        {
          priority: "medium",
          title: "Reduce loan application backlog",
          summary: "#{obs[:metadata][:pending_review]} applications need initial review.",
          action_text: "Temporarily assign additional staff to loan review duties until backlog clears.",
          confidence_score: 0.82
        }
      elsif obs[:title].include?("pending release")
        {
          priority: "medium",
          title: "Release approved loans",
          summary: "#{obs[:metadata][:pending_release]} loans are approved but not yet released.",
          action_text: "Coordinate with members to schedule loan release and complete disbursement.",
          confidence_score: 0.85
        }
      end
    end

    def build_risk_recommendation(obs)
      if obs[:title].include?("PAR30")
        {
          priority: obs[:severity] == "critical" ? "critical" : "high",
          title: "Address PAR30 increase",
          summary: "PAR30 is at critical level. Review delinquent accounts and intensify collection efforts for accounts approaching 30 days past due.",
          action_text: "Conduct portfolio review meeting, identify top 5 delinquent accounts by exposure, and develop workout plans.",
          confidence_score: 0.87
        }
      elsif obs[:title].include?("defaulted")
        {
          priority: "high",
          title: "Manage defaulted loan portfolio",
          summary: "#{obs[:metadata][:defaulted_count]} loans are in default status.",
          action_text: "Review defaulted accounts for possible restructure or legal action. Identify accounts that can be rehabilitated.",
          confidence_score: 0.83
        }
      end
    end

    def build_savings_recommendation(obs)
      if obs[:title].include?("dormant")
        {
          priority: "medium",
          title: "Reactivate dormant savings accounts",
          summary: "High number of dormant accounts. Consider outreach program.",
          action_text: "Launch a savings reactivation campaign targeting accounts inactive for 90+ days with special promotion.",
          confidence_score: 0.75
        }
      elsif obs[:title].include?("withdrawal")
        {
          priority: "high",
          title: "Investigate savings withdrawal spike",
          summary: "Unusual savings outflow detected in the last 7 days.",
          action_text: "Review withdrawal patterns to identify if this is seasonal or requires liquidity management action.",
          confidence_score: 0.80
        }
      end
    end

    def build_membership_recommendation(obs)
      if obs[:title].include?("portal")
        {
          priority: "low",
          title: "Increase portal adoption",
          summary: "Many members have not activated portal access.",
          action_text: "Send SMS/email campaign to inactive members encouraging portal registration.",
          confidence_score: 0.70
        }
      elsif obs[:title].include?("incomplete")
        {
          priority: "low",
          title: "Follow up on incomplete applications",
          summary: "Several loan applications are stuck in draft status.",
          action_text: "Contact members with incomplete applications to offer assistance in completing their loan applications.",
          confidence_score: 0.72
        }
      end
    end

    def build_cash_recommendation(obs)
      {
        priority: "high",
        title: "Resolve cash session variances",
        summary: "Unbalanced teller sessions require immediate investigation.",
        action_text: "Review each unbalanced session with the assigned teller to identify and correct discrepancies.",
        confidence_score: 0.90
      }
    end

    def build_staff_recommendation(obs)
      {
        priority: "medium",
        title: "Follow up on inactive staff",
        summary: "Several staff members have no recorded activity today.",
        action_text: "Remind staff to log their activities and check in with team leads on workload distribution.",
        confidence_score: 0.78
      }
    end

    def format_cents(cents)
      return "0.00" unless cents
      format("%.2f", cents.to_f / 100)
    end
  end
end
