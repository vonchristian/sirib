puts "Seeding management module for #{@coop.name}..."

headquarters = nil

unless Management::Branch.where(cooperative: @coop).exists?
  headquarters = Management::Branch.create!(
    name: "Head Office",
    code: "HQ",
    address: "123 Main Street",
    contact_number: "+63-2-555-0001",
    status: :active,
    cooperative: @coop
  )

  Management::Branch.create!(
    name: "Makati Branch",
    code: "MKT",
    address: "456 Ayala Avenue, Makati City",
    contact_number: "+63-2-555-0002",
    status: :active,
    parent: headquarters,
    cooperative: @coop
  )

  Management::Branch.create!(
    name: "Quezon City Branch",
    code: "QC",
    address: "789 Commonwealth Avenue, Quezon City",
    contact_number: "+63-2-555-0003",
    status: :active,
    parent: headquarters,
    cooperative: @coop
  )
end

headquarters ||= Management::Branch.where(cooperative: @coop).find_by!(code: "HQ")

department_names = ["Administration", "Lending", "Savings", "Accounting", "Compliance"]
Management::Branch.where(cooperative: @coop).find_each do |branch|
  department_names.each do |dept_name|
    Management::Department.find_or_create_by!(
      branch: branch,
      name: dept_name,
      cooperative: @coop
    ) do |d|
      d.code = "#{branch.code}_#{dept_name.parameterize(separator: "_")}"
    end
  end
end

unless Management::Role.where(cooperative: @coop).exists?
  roles = [
    { name: "Board Member", code: "board_member", description: "Board of Directors member with governance authority", rank: 90 },
    { name: "General Manager", code: "general_manager", description: "Full operational oversight authority", rank: 80 },
    { name: "Branch Manager", code: "branch_manager", description: "Branch-level control and performance monitoring", rank: 70 },
    { name: "Loan Officer", code: "loan_officer", description: "Loan origination and processing", rank: 40 },
    { name: "Teller", code: "teller", description: "Cash handling and customer transactions", rank: 30 },
    { name: "Accountant", code: "accountant", description: "Financial record keeping and reporting", rank: 50 },
    { name: "Auditor", code: "auditor", description: "Read-only access across all modules for auditing", rank: 60 },
    { name: "System Admin", code: "system_admin", description: "System configuration and administration", rank: 99 }
  ]
  roles.each { |attrs| Management::Role.create!(attrs.merge(cooperative: @coop)) }
end

subjects = %w[member loan savings time_deposit share_capital treasury accounting branch policy configuration approval_workflow alert audit_log user role report system ai_dashboard]
actions = %w[view create update delete approve reject configure export]

subjects.each do |subject|
  actions.each do |action|
    Management::Permission.find_or_create_by!(action: action, subject: subject, cooperative: @coop)
  end
end

role_permissions = {
  "board_member" => {
    view: subjects.map(&:to_sym),
    approve: [:policy],
    export: [:report]
  },
  "general_manager" => {
    view: subjects.map(&:to_sym),
    create: [:member, :loan, :savings, :time_deposit, :share_capital],
    update: [:member, :loan, :savings, :time_deposit, :share_capital, :treasury, :accounting, :branch, :policy, :configuration],
    approve: [:loan, :policy, :configuration, :approval_workflow],
    reject: [:loan, :policy, :approval_workflow],
    export: [:report]
  },
  "branch_manager" => {
    view: [:member, :loan, :savings, :time_deposit, :share_capital, :treasury, :accounting, :branch, :policy, :report, :ai_dashboard],
    create: [:member, :loan],
    update: [:member, :loan, :branch],
    approve: [:loan],
    export: [:report]
  },
  "loan_officer" => {
    view: [:member, :loan, :savings],
    create: [:loan],
    update: [:loan],
    delete: [:loan]
  },
  "teller" => {
    view: [:member, :savings, :treasury],
    create: [:savings],
    update: [:savings, :treasury]
  },
  "accountant" => {
    view: [:member, :accounting, :treasury, :report],
    create: [:accounting],
    update: [:accounting, :treasury],
    export: [:report]
  },
  "auditor" => {
    view: subjects.map(&:to_sym),
    export: [:report, :audit_log]
  },
  "system_admin" => {
    view: subjects.map(&:to_sym),
    create: subjects.map(&:to_sym),
    update: subjects.map(&:to_sym),
    delete: subjects.map(&:to_sym),
    approve: subjects.map(&:to_sym),
    reject: subjects.map(&:to_sym),
    configure: subjects.map(&:to_sym),
    export: subjects.map(&:to_sym)
  }
}

role_permissions.each do |role_code, perm_map|
  role = Management::Role.where(cooperative: @coop).find_by!(code: role_code)
  perm_map.each do |action, perm_subjects|
    perm_subjects.each do |subject|
      permission = Management::Permission.where(cooperative: @coop).find_by!(action: action, subject: subject)
      Management::RolePermission.find_or_create_by!(role: role, permission: permission, cooperative: @coop)
    end
  end
end

unless Rails.env.test?
  hq = Management::Branch.where(cooperative: @coop).find_by(code: "HQ")
  general_manager_role = Management::Role.where(cooperative: @coop).find_by(code: "general_manager")
  User.where(cooperative: @coop, role: :manager).find_each do |user|
    Management::RoleAssignment.find_or_create_by!(
      user: user,
      role: general_manager_role,
      branch: hq,
      cooperative: @coop,
      active_from: Date.current
    )
  end
end

unless Management::ApprovalWorkflow.where(cooperative: @coop).exists?
  loan_officer_role = Management::Role.where(cooperative: @coop).find_by!(code: "loan_officer")
  branch_manager_role = Management::Role.where(cooperative: @coop).find_by!(code: "branch_manager")
  general_manager_role = Management::Role.where(cooperative: @coop).find_by!(code: "general_manager")
  system_admin_role = Management::Role.where(cooperative: @coop).find_by!(code: "system_admin")
  board_member_role = Management::Role.where(cooperative: @coop).find_by!(code: "board_member")

  loan_approval = Management::ApprovalWorkflow.create!(
    name: "Loan Approval",
    description: "Multi-tier loan approval process",
    cooperative: @coop
  )

  loan_approval.steps.create!([
    { sequence: 1, approver_role: loan_officer_role, threshold_cents_min: 0, threshold_cents_max: 5_000_000, cooperative: @coop },
    { sequence: 2, approver_role: branch_manager_role, threshold_cents_min: 5_000_100, threshold_cents_max: 50_000_000, cooperative: @coop },
    { sequence: 3, approver_role: general_manager_role, threshold_cents_min: 50_000_100, threshold_cents_max: nil, cooperative: @coop }
  ])

  config_change = Management::ApprovalWorkflow.create!(
    name: "Configuration Change",
    description: "System configuration change approval",
    cooperative: @coop
  )

  config_change.steps.create!([
    { sequence: 1, approver_role: system_admin_role, cooperative: @coop },
    { sequence: 2, approver_role: general_manager_role, cooperative: @coop }
  ])

  policy_approval = Management::ApprovalWorkflow.create!(
    name: "Policy Approval",
    description: "Policy review and approval process",
    cooperative: @coop
  )

  policy_approval.steps.create!([
    { sequence: 1, approver_role: general_manager_role, cooperative: @coop },
    { sequence: 2, approver_role: board_member_role, cooperative: @coop }
  ])
end

unless Management::AlertSubscription.where(cooperative: @coop).exists?
  alert_types = %w[low_cash large_transaction compliance_breach system_error member_activity loan_due]
  channels = %w[email in_app dashboard]

  Management::Role.where(cooperative: @coop, code: %w[general_manager system_admin]).find_each do |role|
    role.role_assignments.includes(:user).find_each do |assignment|
      alert_types.each do |alert_type|
        channels.each do |channel|
          Management::AlertSubscription.find_or_create_by!(
            user: assignment.user,
            alert_type: alert_type,
            channel: channel,
            cooperative: @coop
          )
        end
      end
    end
  end
end

unless Management::Policy.where(cooperative: @coop).exists?
  admin_user = User.where(cooperative: @coop, role: :manager).first

  max_loan = Management::Policy.create!(
    name: "Maximum Loan Amount",
    code: "max_loan_amount",
    category: "lending",
    description: "Sets the maximum loan amount based on member classification",
    status: :active,
    created_by: admin_user,
    cooperative: @coop
  )

  max_loan.rules.create!([
    { field: "loan_amount", operator: "lte", value: "500000", effect: :allow, cooperative: @coop },
    { field: "member_tier", operator: "eq", value: "regular", effect: :allow, cooperative: @coop },
    { field: "loan_amount", operator: "gt", value: "500000", effect: :deny, cooperative: @coop }
  ])

  teller_cash = Management::Policy.create!(
    name: "Teller Cash Limit",
    code: "teller_cash_limit",
    category: "cash_management",
    description: "Maximum cash that a teller can hold at any time",
    status: :active,
    created_by: admin_user,
    cooperative: @coop
  )

  teller_cash.rules.create!([
    { field: "cash_on_hand", operator: "lte", value: "100000", effect: :allow, cooperative: @coop },
    { field: "cash_on_hand", operator: "gt", value: "100000", effect: :deny, cooperative: @coop }
  ])

  min_savings = Management::Policy.create!(
    name: "Minimum Savings Balance",
    code: "min_savings_balance",
    category: "savings",
    description: "Minimum maintaining balance for savings accounts",
    status: :active,
    created_by: admin_user,
    cooperative: @coop
  )

  min_savings.rules.create!([
    { field: "balance", operator: "gte", value: "500", effect: :allow, cooperative: @coop },
    { field: "balance", operator: "lt", value: "500", effect: :deny, cooperative: @coop }
  ])
end

unless Ai::Agent.where(cooperative: @coop).exists?
  Ai::Agent.create!(
    name: "Branch Manager AI",
    description: "Monitors branch operations, detects issues, and generates daily digests with recommendations.",
    enabled: true,
    schedule: "daily",
    cooperative: @coop
  )
  puts "  AI Agent created: Branch Manager AI"
end

puts "  Management seeded: branches, departments, roles, permissions, workflows, policies"