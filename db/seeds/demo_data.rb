puts "Seeding demo data..."

hq = Management::Branch.find_by(code: "HQ")
mkt = Management::Branch.find_by(code: "MKT")
qc = Management::Branch.find_by(code: "QC")

admin_user = User.find_by(email_address: "admin@example.com")

# ── 1. FULL USER ROSTER WITH ROLE ASSIGNMENTS ──────────────────────────

demo_users = {
  "board@example.com"          => { role: :manager,     name: "Board Member" },
  "gm@example.com"             => { role: :manager,     name: "General Manager" },
  "branch_mgr_mkt@example.com" => { role: :manager,     name: "Branch Manager MKT" },
  "branch_mgr_qc@example.com"  => { role: :manager,     name: "Branch Manager QC" },
  "loan_officer@example.com"   => { role: :loan_officer,name: "Loan Officer" },
  "teller@example.com"         => { role: :treasurer,   name: "Teller" },
  "accountant@example.com"     => { role: :accountant,  name: "Accountant" },
  "auditor@example.com"        => { role: :accountant,  name: "Auditor" }
}

created_users = {}
demo_users.each do |email, attrs|
  user = User.find_or_create_by!(email_address: email) do |u|
    u.password = "password123"
    u.role = attrs[:role]
  end
  created_users[email] = user
end

# Assign roles to users
role_assignments = [
  { email: "board@example.com",          role_code: "board_member",    branch: hq  },
  { email: "gm@example.com",             role_code: "general_manager", branch: hq  },
  { email: "branch_mgr_mkt@example.com", role_code: "branch_manager",  branch: mkt },
  { email: "branch_mgr_qc@example.com",  role_code: "branch_manager",  branch: qc  },
  { email: "loan_officer@example.com",   role_code: "loan_officer",    branch: mkt },
  { email: "teller@example.com",         role_code: "teller",          branch: mkt },
  { email: "accountant@example.com",     role_code: "accountant",      branch: hq  },
  { email: "auditor@example.com",        role_code: "auditor",         branch: hq  },
  { email: "admin@example.com",          role_code: "system_admin",    branch: hq  },
  { email: "admin@example.com",          role_code: "general_manager", branch: hq  },
  { email: "manager@sirib.com",          role_code: "general_manager", branch: hq  },
]

role_assignments.each do |ra|
  role = Management::Role.find_by(code: ra[:role_code])
  user = User.find_by(email_address: ra[:email])
  next unless role && user

  Management::RoleAssignment.find_or_create_by!(user: user, role: role, branch: ra[:branch])
end

# ── 2. EQUITY PRODUCTS & ACCOUNTS ─────────────────────────────────────

unless Equity::Product.exists?
  common = Equity::Product.create!(
    product_code: "COMMON",
    name: "Common Share",
    description: "Regular common share with voting rights",
    share_type: :common,
    price_per_share_cents: 1_000_00,
    minimum_required_shares: 1,
    maximum_allowed_shares: 1000,
    minimum_initial_purchase: 1,
    voting_rights: true,
    dividend_eligible: true,
    redeemable: true
  )

  preferred = Equity::Product.create!(
    product_code: "PREFERRED",
    name: "Preferred Share",
    description: "Preferred share with dividend priority",
    share_type: :preferred,
    price_per_share_cents: 5_000_00,
    minimum_required_shares: 1,
    maximum_allowed_shares: 500,
    minimum_initial_purchase: 1,
    voting_rights: false,
    dividend_eligible: true,
    redeemable: true
  )
end

member1 = Member.find_by(first_name: "Maria", last_name: "Cruz")
member2 = Member.find_by(first_name: "Juan", last_name: "Reyes")
member3 = Member.find_by(first_name: "Elena", last_name: "Villanueva")
members_sample = [member1, member2, member3].compact

common_product = Equity::Product.find_by(product_code: "COMMON")
preferred_product = Equity::Product.find_by(product_code: "PREFERRED")

members_sample.each_with_index do |member, i|
  next unless common_product

  account = Equity::Account.find_or_create_by!(member: member, share_product: common_product) do |a|
    a.status = "active"
    a.opened_by_id = admin_user.id
    a.shares_owned = (i + 1) * 10
    a.paid_up_shares = (i + 1) * 10
  end

  Equity::Transaction.find_or_create_by!(
    share_capital_account: account,
    transaction_type: :purchase,
    reference_number: "EQ-#{format('%04d', i + 1)}"
  ) do |t|
    t.shares = (i + 1) * 10
    t.price_per_share_cents = 1_000_00
    t.total_amount_cents = (i + 1) * 10 * 1_000_00
    t.status = :completed
    t.posted_at = 30.days.ago
    t.posted_by_id = admin_user.id
  end
end

# ── 3. LOAN APPLICATIONS & LOANS ──────────────────────────────────────

salary_loan = Lending::LoanProduct.find_by(name: "Regular Salary Loan")
emergency_loan = Lending::LoanProduct.find_by(name: "Emergency Loan")
educ_loan = Lending::LoanProduct.find_by(name: "Educational Loan")

if salary_loan
  members_sample.each_with_index do |member, i|
    existing = Lending::LoanApplication.find_by(reference_number: "LA-#{format('%04d', i + 1)}")
    next if existing

    app = Lending::LoanApplication.create!(
      cooperative: Cooperative.first,
      member: member,
      loan_product: [salary_loan, emergency_loan, educ_loan][i],
      uuid: SecureRandom.uuid,
      status: "approved",
      current_step: 5,
      amount_cents: [(i + 1) * 50_000_00, (i + 1) * 20_000_00, (i + 1) * 100_000_00][i],
      interest_rate: [1.5, 2.0, 1.0][i],
      term_months: [12, 6, 24][i],
      submitted_at: 45.days.ago,
      approved_at: 40.days.ago,
      reference_number: "LA-#{format('%04d', i + 1)}"
    )

    unless Lending::Loan.exists?(loan_application_id: app.id)
      loan = Lending::Loan.create!(
        loan_application: app,
        member: member,
        loan_product: app.loan_product,
        principal_cents: app.amount_cents,
        interest_rate: app.interest_rate,
        interest_calculation: app.loan_product.interest_calculation,
        term_months: app.term_months,
        outstanding_principal_cents: app.amount_cents,
        status: :active,
        disbursed_at: 38.days.ago,
        reference_number: "LN-#{format('%04d', i + 1)}"
      )

      cash_account = Accounting::Account.find_by(account_code: "11131")
      loan_receivable = Accounting::Account.find_by(account_code: "11210")
      if cash_account && loan_receivable
        Accounting::PostEntryService.run!(
          description: "Loan disbursement - #{member.first_name} #{member.last_name}",
          reference_number: "DSB-#{format('%04d', i + 1)}",
          posted_at: 38.days.ago,
          debits: [{ account: loan_receivable, amount: app.amount_cents }],
          credits: [{ account: cash_account, amount: app.amount_cents }]
        )
      end
    end
  end
end

# ── 4. SAVINGS ACCOUNTS ───────────────────────────────────────────────

regular_savings = Treasury::SavingsProduct.find_by(name: "Regular Savings")
if regular_savings
  members_sample.each_with_index do |member, i|
    next if Treasury::SavingsAccount.exists?(depositor: member)

    account = Treasury::SavingsAccount.create!(
      savings_product: regular_savings,
      depositor: member,
      account_type: :personal,
      status: "active"
    )

    next unless account.liability_account

    cash_account = Accounting::Account.find_by(account_code: "11131")
    if cash_account
      Accounting::PostEntryService.run!(
        description: "Initial savings deposit - #{member.first_name} #{member.last_name}",
        reference_number: "SVP-#{format('%04d', i + 1)}",
        posted_at: 25.days.ago,
        debits: [{ account: cash_account, amount: (i + 1) * 5_000_00 }],
        credits: [{ account: account.liability_account, amount: (i + 1) * 5_000_00 }]
      )
    end

    Treasury::SavingsTransaction.create!(
      savings_account: account,
      transaction_type: :deposit,
      amount_cents: (i + 1) * 5_000_00,
      cash_account: cash_account,
      reference_number: "STX-#{format('%04d', i + 1)}",
      status: :completed,
      posted_at: 25.days.ago
    )
  end
end

# ── 5. TIME DEPOSITS ──────────────────────────────────────────────────

td_product = Treasury::TimeDepositProduct.find_or_create_by!(name: "Regular Time Deposit") do |p|
  p.description = "Standard 30-day time deposit with competitive interest"
  p.minimum_deposit_cents = 5_000_00
  p.interest_rate = 0.035
  p.term_in_days = 30
  p.status = "active"
end
if td_product
  members_sample.each_with_index do |member, i|
    next if Treasury::TimeDeposit.exists?(depositor: member)

    Treasury::TimeDeposit.create!(
      depositor: member,
      time_deposit_product: td_product,
      amount_cents: (i + 1) * 100_000_00,
      interest_rate: td_product.interest_rate,
      matured_on: 60.days.from_now,
      interest_earned_cents: 0,
      status: :active,
      opened_at: 30.days.ago
    )
  end
end

# ── 6. ADDITIONAL ACCOUNTING ENTRIES ──────────────────────────────────

cash_on_hand = Accounting::Account.find_by(account_code: "11110")
interest_income = Accounting::Account.find_by(account_code: "40110")
salaries_expense = Accounting::Account.find_by(account_code: "60010")
rent_expense = Accounting::Account.find_by(account_code: "60090")
service_fees = Accounting::Account.find_by(account_code: "40120")
bank_acct = Accounting::Account.find_by(account_code: "11131")
bank_charges = Accounting::Account.find_by(account_code: "60220")

unless Accounting::Entry.exists?(reference_number: "ENT-DEMO-001")
  Accounting::PostEntryService.run!(
    description: "Interest income from loans - monthly accrual",
    reference_number: "ENT-DEMO-001",
    posted_at: 15.days.ago,
    debits: [{ account: Accounting::Account.find_by(account_code: "11210"), amount: 75_000_00 }],
    credits: [{ account: interest_income, amount: 75_000_00 }]
  )
end

unless Accounting::Entry.exists?(reference_number: "ENT-DEMO-002")
  Accounting::PostEntryService.run!(
    description: "Monthly salaries and wages",
    reference_number: "ENT-DEMO-002",
    posted_at: 10.days.ago,
    debits: [{ account: salaries_expense, amount: 250_000_00 }],
    credits: [{ account: bank_acct, amount: 250_000_00 }]
  )
end

unless Accounting::Entry.exists?(reference_number: "ENT-DEMO-003")
  Accounting::PostEntryService.run!(
    description: "Monthly rent payment",
    reference_number: "ENT-DEMO-003",
    posted_at: 5.days.ago,
    debits: [{ account: rent_expense, amount: 50_000_00 }],
    credits: [{ account: bank_acct, amount: 50_000_00 }]
  )
end

unless Accounting::Entry.exists?(reference_number: "ENT-DEMO-004")
  Accounting::PostEntryService.run!(
    description: "Service fees collected from loan processing",
    reference_number: "ENT-DEMO-004",
    posted_at: 3.days.ago,
    debits: [{ account: cash_on_hand, amount: 12_000_00 }],
    credits: [{ account: service_fees, amount: 12_000_00 }]
  )
end

unless Accounting::Entry.exists?(reference_number: "ENT-DEMO-005")
  Accounting::PostEntryService.run!(
    description: "Bank service charges",
    reference_number: "ENT-DEMO-005",
    posted_at: 1.day.ago,
    debits: [{ account: bank_charges, amount: 2_500_00 }],
    credits: [{ account: bank_acct, amount: 2_500_00 }]
  )
end

# ── 7. BRANCH PERFORMANCE SNAPSHOTS ───────────────────────────────────

perf_data = [
  {
    branch: hq,
    metrics: {
      loan_portfolio_cents: 8_500_000_00,
      savings_balance_cents: 3_200_000_00,
      delinquency_rate: 2.1,
      collection_efficiency: 95.3,
      cash_flow_position_cents: 4_100_000_00,
      estimated_profitability_cents: 1_200_000_00,
      total_members: 45
    }
  },
  {
    branch: mkt,
    metrics: {
      loan_portfolio_cents: 5_200_000_00,
      savings_balance_cents: 2_800_000_00,
      delinquency_rate: 3.8,
      collection_efficiency: 91.7,
      cash_flow_position_cents: 2_300_000_00,
      estimated_profitability_cents: 780_000_00,
      total_members: 32
    }
  },
  {
    branch: qc,
    metrics: {
      loan_portfolio_cents: 3_800_000_00,
      savings_balance_cents: 1_900_000_00,
      delinquency_rate: 5.2,
      collection_efficiency: 88.4,
      cash_flow_position_cents: 1_600_000_00,
      estimated_profitability_cents: 520_000_00,
      total_members: 28
    }
  }
]

perf_data.each do |data|
  Management::BranchPerformanceSnapshot.find_or_create_by!(
    branch: data[:branch],
    snapshot_date: Date.current
  ) do |s|
    s.metrics = data[:metrics]
  end

  Management::BranchPerformanceSnapshot.find_or_create_by!(
    branch: data[:branch],
    snapshot_date: 7.days.ago.to_date
  ) do |s|
    prev = data[:metrics].merge(
      "loan_portfolio_cents" => (data[:metrics][:loan_portfolio_cents] * 0.95).to_i,
      "savings_balance_cents" => (data[:metrics][:savings_balance_cents] * 0.97).to_i
    )
    s.metrics = prev
  end
end

# ── 8. RISK INDICATORS ────────────────────────────────────────────────

risk_data = [
  { type: "credit_risk_delinquency", value: 3.5, threshold: 5.0, status: :elevated, branch: nil },
  { type: "liquidity_ratio", value: 0.35, threshold: 0.2, status: :normal, branch: nil },
  { type: "portfolio_at_risk", value: 4.2, threshold: 5.0, status: :elevated, branch: nil },
  { type: "credit_risk_delinquency", value: 2.1, threshold: 5.0, status: :normal, branch: hq },
  { type: "credit_risk_delinquency", value: 3.8, threshold: 5.0, status: :elevated, branch: mkt },
  { type: "credit_risk_delinquency", value: 5.2, threshold: 5.0, status: :critical, branch: qc },
  { type: "liquidity_ratio", value: 0.42, threshold: 0.2, status: :normal, branch: hq },
  { type: "portfolio_at_risk", value: 2.8, threshold: 5.0, status: :normal, branch: hq },
  { type: "portfolio_at_risk", value: 4.5, threshold: 5.0, status: :elevated, branch: mkt },
  { type: "portfolio_at_risk", value: 6.1, threshold: 5.0, status: :critical, branch: qc },
]

risk_data.each do |data|
  Management::RiskIndicator.find_or_create_by!(
    indicator_type: data[:type],
    branch: data[:branch],
    as_of_date: Date.current
  ) do |r|
    r.value = data[:value]
    r.threshold = data[:threshold]
    r.status = data[:status]
  end
end

# ── 9. SYSTEM HEALTH SNAPSHOTS ────────────────────────────────────────

health_metrics = [
  { name: "transaction_throughput", value: 142.5, unit: "tps", status: :healthy },
  { name: "queue_depth", value: 8, unit: "jobs", status: :healthy },
  { name: "posting_latency_ms", value: 234.0, unit: "ms", status: :healthy },
  { name: "error_rate", value: 0.5, unit: "percent", status: :healthy },
  { name: "database_connections", value: 12, unit: "conn", status: :healthy },
  { name: "memory_usage_mb", value: 456, unit: "MB", status: :healthy },
  { name: "response_time_ms", value: 89, unit: "ms", status: :healthy },
  { name: "active_users", value: 4, unit: "users", status: :healthy },
]

health_metrics.each do |m|
  3.times do |i|
    Management::SystemHealthSnapshot.find_or_create_by!(
      metric_name: m[:name],
      captured_at: i.hours.ago.beginning_of_hour
    ) do |s|
      s.value = m[:value] + rand(-10.0..10.0)
      s.unit = m[:unit]
      s.status = m[:status]
    end
  end
end

# ── 10. ALERTS ────────────────────────────────────────────────────────

alerts = [
  { alert_type: "loan_delinquency", severity: :warning, title: "QC Branch delinquency rate exceeded 5%",
    message: "Quezon City branch delinquency rate is at 5.2%, above the 5% threshold.", source: "risk_monitoring" },
  { alert_type: "cash_shortage", severity: :critical, title: "Low cash balance in Makati Branch",
    message: "Makati Branch cash on hand is below minimum operating threshold.", source: "system" },
  { alert_type: "approval_threshold", severity: :info, title: "Large loan pending approval",
    message: "Loan application LA-003 exceeds standard threshold and requires board approval.", source: "approval_workflow" },
  { alert_type: "system_health", severity: :warning, title: "High memory usage detected",
    message: "System memory usage at 85% capacity. Consider scaling up.", source: "system_health" },
  { alert_type: "compliance", severity: :warning, title: "Pending policy acknowledgments",
    message: "3 users have not acknowledged the updated lending policy.", source: "compliance" },
]

alerts.each do |attrs|
  Management::Alert.find_or_create_by!(
    alert_type: attrs[:alert_type],
    title: attrs[:title],
    severity: attrs[:severity],
    source: attrs[:source]
  ) do |a|
    a.message = attrs[:message]
    a.status = :active
  end
end

# ── 11. APPROVAL REQUESTS ──────────────────────────────────────────────

loan_workflow = Management::ApprovalWorkflow.find_by(code: "loan_approval")
config_workflow = Management::ApprovalWorkflow.find_by(code: "config_change")
policy_workflow = Management::ApprovalWorkflow.find_by(code: "policy_approval")

gm = User.find_by(email_address: "gm@example.com")
loan_officer = User.find_by(email_address: "loan_officer@example.com")

if loan_workflow && !Management::ApprovalRequest.exists?(workflow: loan_workflow)
  request = Management::ApprovalRequest.create!(
    requestable_type: "Lending::LoanApplication",
    requestable_id: Lending::LoanApplication.first&.id || 0,
    workflow: loan_workflow,
    status: "pending",
    requested_by: loan_officer || admin_user,
    current_step: loan_workflow.steps.first.sequence,
    reason: "New loan application requiring approval"
  )

  Management::Approval.create!(
    approval_request: request,
    step: loan_workflow.steps.first,
    approver: gm || admin_user,
    status: "approved",
    comment: "Approved - within standard limits",
    signed_at: 1.day.ago
  )
end

if policy_workflow && !Management::ApprovalRequest.exists?(workflow: policy_workflow)
  Management::ApprovalRequest.create!(
    requestable_type: "Management::Policy",
    requestable_id: Management::Policy.first&.id || 0,
    workflow: policy_workflow,
    status: "pending",
    requested_by: gm || admin_user,
    current_step: policy_workflow.steps.first.sequence,
    reason: "Review and approval of updated lending policy"
  )
end



# ── 12. CONFIGURATIONS ────────────────────────────────────────────────

configs = {
  "loan_default_interest_rate" => { value: 1.5, unit: "percent", min: 0.5, max: 3.0 },
  "savings_base_interest_rate" => { value: 0.25, unit: "percent" },
  "max_loan_to_value_ratio" => { value: 80, unit: "percent" },
  "late_payment_penalty_rate" => { value: 3.0, unit: "percent", grace_period_days: 3 },
  "cash_session_timeout_minutes" => { value: 480, unit: "minutes" }
}

configs.each do |key, val|
  Management::Configuration.find_or_create_by!(key: key) do |c|
    c.value = val
    c.status = :active
    c.changed_by = admin_user
    c.approved_by = admin_user
    c.approved_at = Time.current
  end
end

if config_workflow && Management::Configuration.exists? && !Management::ApprovalRequest.exists?(workflow: config_workflow)
  Management::ApprovalRequest.create!(
    requestable: Management::Configuration.first,
    workflow: config_workflow,
    status: "pending",
    requested_by: admin_user,
    current_step: config_workflow.steps.first.sequence,
    reason: "Update interest rate configuration for new loan product"
  )
end

# ── 13. AUDIT LOGS ────────────────────────────────────────────────────

unless Management::AuditLog.exists?
  gm_user = gm || admin_user

  actions = [
    { action: "user_login", auditable: gm_user, actor: gm_user },
    { action: "policy_created", auditable: Management::Policy.first, actor: admin_user },
    { action: "configuration_updated", auditable: Management::Configuration.first, actor: admin_user },
    { action: "branch_performance_reviewed", auditable: hq, actor: gm_user },
    { action: "approval_workflow_updated", auditable: loan_workflow, actor: admin_user },
    { action: "report_exported", auditable: nil, actor: gm_user },
  ]

  actions.each_with_index do |attrs, i|
    Management::AuditLog.create!(
      auditable: attrs[:auditable],
      action: attrs[:action],
      actor: attrs[:actor],
      actor_role: attrs[:actor].management_roles.first&.code,
      ip_address: "192.168.1.#{100 + i}",
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      before_state: { previous_value: "old_value" },
      after_state: { new_value: "new_value" },
      created_at: (actions.size - i).hours.ago
    )
  end
end

# ── 14. ALERT SUBSCRIPTIONS ────────────────────────────────────────────

unless Management::AlertSubscription.where(user: admin_user).exists?
  alert_types = Management::Alert.distinct.pluck(:alert_type)
  %w[email in_app dashboard].each do |channel|
    alert_types.each do |atype|
      User.where(email_address: %w[gm@example.com admin@example.com]).find_each do |u|
        Management::AlertSubscription.find_or_create_by!(
          user: u, alert_type: atype, channel: channel
        )
      end
    end
  end
end

# ── 15. SUMMARY ────────────────────────────────────────────────────────

puts ""
puts "✅ Demo data seeded successfully!"
puts "   #{created_users.size + 2} users (including pre-existing)"
puts "   #{Management::RoleAssignment.count} role assignments"
puts "   #{Equity::Product.count} equity products"
puts "   #{Equity::Account.count} equity accounts"
puts "   #{Equity::Transaction.count} equity transactions"
puts "   #{Lending::LoanApplication.count} loan applications"
puts "   #{Lending::Loan.count} active loans"
puts "   #{Treasury::SavingsAccount.count} savings accounts"
puts "   #{Treasury::TimeDeposit.count} time deposits"
puts "   #{Accounting::Entry.count} journal entries"
puts "   #{Management::BranchPerformanceSnapshot.count} branch performance snapshots"
puts "   #{Management::RiskIndicator.count} risk indicators"
puts "   #{Management::SystemHealthSnapshot.count} system health snapshots"
puts "   #{Management::Alert.count} active alerts"
puts "   #{Management::ApprovalRequest.count} approval requests"
puts "   #{Management::Configuration.count} configurations"
puts "   #{Management::AuditLog.count} audit log entries"
puts ""
puts "   Login credentials:"
puts "   - board@example.com / password123 (Board Member)"
puts "   - gm@example.com / password123 (General Manager)"
puts "   - branch_mgr_mkt@example.com / password123 (Branch Manager - MKT)"
puts "   - admin@example.com / password123 (System Admin)"
