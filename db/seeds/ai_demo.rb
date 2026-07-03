puts "  Seeding AI demo data for #{@coop.name}..."

branches = Management::Branch.where(cooperative: @coop).to_a
return if branches.empty?

hq = branches.find { |b| b.code == "HQ" } || branches.first
satellite = branches.find { |b| b.code != "HQ" } || branches.last

observation_templates = [
  {
    branch: hq, category: "collections", severity: "critical",
    title: "High delinquency rate in #{hq.name}",
    summary: "Delinquency rate has reached 6.2%, exceeding the 5% threshold. #{hq.name} has 45 accounts past due by more than 30 days, representing PHP 2.3M in outstanding principal.",
    detected_at: 3.hours.ago
  },
  {
    branch: hq, category: "liquidity", severity: "high",
    title: "Cash position below minimum reserve",
    summary: "Current cash position is PHP 850,000, below the required PHP 1,000,000 minimum reserve. Projected withdrawals in the next 48 hours could further strain liquidity.",
    detected_at: 5.hours.ago
  },
  {
    branch: hq, category: "operations", severity: "medium",
    title: "Teller overtime increasing",
    summary: "Teller overtime has increased 22% week-over-week. Average transaction processing time has risen to 4.5 minutes due to peak-hour congestion.",
    detected_at: 8.hours.ago
  },
  {
    branch: hq, category: "membership", severity: "low",
    title: "Pending membership applications exceeding SLA",
    summary: "8 new member applications have been pending review for more than 3 business days, exceeding the 48-hour service level agreement.",
    detected_at: 1.day.ago
  },
  {
    branch: satellite, category: "collections", severity: "high",
    title: "Portfolio at risk in #{satellite.name}",
    summary: "#{satellite.name} shows PHP 1.1M in loans overdue by 30+ days. Collection efficiency dropped to 87% this month from 93% last month.",
    detected_at: 4.hours.ago
  },
  {
    branch: satellite, category: "compliance", severity: "critical",
    title: "Overdue regulatory report — #{satellite.name}",
    summary: "The monthly Branch Operations Report (BOR-2026-06) for #{satellite.name} was due 2 days ago and has not been submitted to the compliance department.",
    detected_at: 2.hours.ago
  },
  {
    branch: satellite, category: "operations", severity: "medium",
    title: "Vault count discrepancy in #{satellite.name}",
    summary: "End-of-day vault count on June 24 showed a PHP 2,500 discrepancy that was not resolved. Pending investigation.",
    detected_at: 18.hours.ago
  },
  {
    branch: hq, category: "system", severity: "high",
    title: "Transaction processing delay detected",
    summary: "Average journal entry posting latency has increased to 2.3 seconds, up from the baseline of 0.8 seconds. Peak-hour throughput is approaching system capacity at 85%.",
    detected_at: 6.hours.ago
  },
  {
    branch: hq, category: "fraud", severity: "critical",
    title: "Suspicious transaction pattern flagged",
    summary: "Three large withdrawals totaling PHP 150,000 were made from a single member account within 2 hours across different branches. Flagged for fraud review.",
    detected_at: 1.hour.ago
  },
  {
    branch: hq, category: "growth", severity: "low",
    title: "Member acquisition rate slowing",
    summary: "New member enrollments this quarter are down 15% compared to the previous quarter. Current marketing campaigns may need reassessment.",
    detected_at: 2.days.ago
  }
]

observations = []
observation_templates.each do |tmpl|
  scope = { branch: tmpl[:branch], title: tmpl[:title], cooperative: @coop }
  next if ::Ai::Observation.exists?(scope)

  obs = ::Ai::Observation.create!(
    branch: tmpl[:branch],
    category: tmpl[:category],
    severity: tmpl[:severity],
    title: tmpl[:title],
    summary: tmpl[:summary],
    detected_at: tmpl[:detected_at],
    cooperative: @coop
  )
  observations << obs
  puts "    Observation created: #{obs.title} (#{obs.severity})"
end

recommendation_templates = [
  {
    observation_index: 0, priority: "critical", status: "open",
    title: "Launch targeted collection drive",
    summary: "Initiate a special collection campaign focusing on accounts 30-60 days past due at #{hq.name}. Assign one collection officer per 15 accounts.",
    action_text: "Schedule collection kickoff meeting with branch manager",
    confidence_score: 0.92
  },
  {
    observation_index: 1, priority: "high", status: "open",
    title: "Review and adjust cash reserve thresholds",
    summary: "Temporarily increase the minimum cash reserve threshold to PHP 1,200,000 for #{hq.name}. Request supplemental cash transfer from treasury.",
    action_text: "Coordinate with treasury for PHP 500,000 cash transfer",
    confidence_score: 0.85
  },
  {
    observation_index: 2, priority: "medium", status: "acknowledged",
    title: "Optimize teller scheduling",
    summary: "Adjust teller shifts to add one additional teller during peak hours (10 AM - 2 PM) and reduce coverage during low-traffic periods.",
    action_text: "Review current schedule and submit revised roster",
    confidence_score: 0.78
  },
  {
    observation_index: 3, priority: "low", status: "dismissed",
    title: "Process pending membership applications",
    summary: "Assign two staff members to process the 8 pending membership applications within 24 hours to meet SLA requirements.",
    action_text: "Reassign staff from back-office to applications processing",
    confidence_score: 0.72
  },
  {
    observation_index: 4, priority: "high", status: "open",
    title: "Intensify collection efforts at #{satellite.name}",
    summary: "Deploy additional collection support to #{satellite.name}. Target the PHP 1.1M overdue portfolio with phone and field visit strategies.",
    action_text: "Arrange field visit schedule for delinquent accounts",
    confidence_score: 0.88
  },
  {
    observation_index: 5, priority: "critical", status: "open",
    title: "File compliance report for #{satellite.name} immediately",
    summary: "Prepare and submit the June Branch Operations Report to the compliance department. Collaborate with the branch accountant to compile required data.",
    action_text: "Contact the branch accountant for data compilation",
    confidence_score: 0.95
  },
  {
    observation_index: 6, priority: "medium", status: "open",
    title: "Investigate vault discrepancy at #{satellite.name}",
    summary: "Conduct a full audit of the June 24 vault transactions to identify the PHP 2,500 discrepancy. Review CCTV footage from the end-of-day count.",
    action_text: "Schedule audit with internal audit team",
    confidence_score: 0.80
  },
  {
    observation_index: 7, priority: "high", status: "open",
    title: "Escalate system performance issue to IT",
    summary: "Report the transaction posting latency issue to the IT team. Consider scaling up Solid Queue workers during peak hours.",
    action_text: "File IT support ticket and monitor queue depth",
    confidence_score: 0.83
  },
  {
    observation_index: 8, priority: "critical", status: "open",
    title: "Flag account for immediate fraud review",
    summary: "Place a temporary hold on withdrawal transactions for the flagged member account. Initiate fraud investigation protocol and notify the member.",
    action_text: "Contact member to verify recent transactions",
    confidence_score: 0.97
  },
  {
    observation_index: 9, priority: "low", status: "dismissed",
    title: "Evaluate member marketing strategy",
    summary: "Review current marketing campaigns and channel performance. Consider launching a member referral program to boost enrollment numbers.",
    action_text: "Request marketing performance report from management",
    confidence_score: 0.65
  }
]

recommendation_templates.each do |tmpl|
  obs = observations[tmpl[:observation_index]]
  next unless obs

  scope = { branch: obs.branch, title: tmpl[:title], cooperative: @coop }
  next if ::Ai::Recommendation.exists?(scope)

  rec = ::Ai::Recommendation.create!(
    branch: obs.branch,
    observation: obs,
    priority: tmpl[:priority],
    status: tmpl[:status],
    title: tmpl[:title],
    summary: tmpl[:summary],
    action_text: tmpl[:action_text],
    confidence_score: tmpl[:confidence_score],
    cooperative: @coop
  )
  puts "    Recommendation created: #{rec.title} (#{rec.priority})"
end

::Ai::Digest.find_or_create_by!(generated_at: Date.current.midnight + 6.hours, branch: hq, cooperative: @coop) do |d|
  d.summary = "#{hq.name} operations are stable but require attention in two critical areas. " \
    "Cash position is PHP 850,000, PHP 150,000 below the minimum reserve. " \
    "Delinquency rate stands at 6.2%, driven primarily by the agricultural loan portfolio. " \
    "Teller overtime costs have increased 22%, suggesting the need for schedule optimization. " \
    "On a positive note, savings deposits grew 3% week-over-week and loan disbursements are on track for the monthly target."
  d.risk_summary = "HIGH: Cash position below minimum reserve (PHP 850K vs PHP 1M target). " \
    "HIGH: Delinquency rate at 6.2% exceeds 5% threshold. " \
    "MEDIUM: 8 pending membership applications exceeding SLA. " \
    "MEDIUM: Portfolio at risk in #{satellite.name} at PHP 1.1M. " \
    "LOW: Teller overtime and operational efficiency trending negative."
  d.observation_count = ::Ai::Observation.where(branch: hq, cooperative: @coop).count
  d.recommendation_count = ::Ai::Recommendation.where(branch: hq, cooperative: @coop).count
  d.cooperative = @coop
end
puts "    Digest created for #{hq.name}"

::Ai::Digest.find_or_create_by!(generated_at: Date.current.midnight + 6.hours, branch: satellite, cooperative: @coop) do |d|
  d.summary = "#{satellite.name} showed mixed results today. " \
    "Collection efficiency dropped to 87%, down from 93% last month, with PHP 1.1M in loans overdue by 30+ days. " \
    "A vault count discrepancy of PHP 2,500 from June 24 remains under investigation. " \
    "The monthly operations report is overdue for submission to the compliance department. " \
    "Member transactions processed on time and cash position remains adequate."
  d.risk_summary = "CRITICAL: Overdue regulatory report not yet submitted. " \
    "HIGH: PHP 1.1M portfolio at risk with declining collection efficiency. " \
    "MEDIUM: Vault count discrepancy of PHP 2,500 unresolved. " \
    "LOW: Staff overtime within acceptable range."
  d.observation_count = ::Ai::Observation.where(branch: satellite, cooperative: @coop).count
  d.recommendation_count = ::Ai::Recommendation.where(branch: satellite, cooperative: @coop).count
  d.cooperative = @coop
end
puts "    Digest created for #{satellite.name}"
