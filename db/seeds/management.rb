puts "Seeding management module..."

headquarters = nil

unless Management::Branch.exists?
  headquarters = Management::Branch.create!(
    name: "Head Office",
    code: "HQ",
    address: "123 Main Street",
    contact_number: "+63-2-555-0001",
    status: :active
  )

  Management::Branch.create!(
    name: "Makati Branch",
    code: "MKT",
    address: "456 Ayala Avenue, Makati City",
    contact_number: "+63-2-555-0002",
    status: :active,
    parent: headquarters
  )

  Management::Branch.create!(
    name: "Quezon City Branch",
    code: "QC",
    address: "789 Commonwealth Avenue, Quezon City",
    contact_number: "+63-2-555-0003",
    status: :active,
    parent: headquarters
  )
end

headquarters ||= Management::Branch.find_by(code: "HQ")

department_names = ["Administration", "Lending", "Savings", "Accounting", "Compliance"]
Management::Branch.find_each do |branch|
  department_names.each do |dept_name|
    Management::Department.find_or_create_by!(
      branch: branch,
      name: dept_name,
      code: "#{branch.code}_#{dept_name.parameterize(separator: "_")}"
    )
  end
end

unless Management::Role.exists?
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
  roles.each { |attrs| Management::Role.create!(attrs) }
end

subjects = %w[member loan savings time_deposit share_capital treasury accounting branch policy configuration approval_workflow alert audit_log user role report system]
actions = %w[view create update delete approve reject configure export]

subjects.each do |subject|
  actions.each do |action|
    Management::Permission.find_or_create_by!(action: action, subject: subject)
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
    view: [:member, :loan, :savings, :time_deposit, :share_capital, :treasury, :accounting, :branch, :policy, :report],
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
  role = Management::Role.find_by!(code: role_code)
  perm_map.each do |action, perm_subjects|
    perm_subjects.each do |subject|
      permission = Management::Permission.find_by!(action: action, subject: subject)
      Management::RolePermission.find_or_create_by!(role: role, permission: permission)
    end
  end
end

unless Rails.env.test?
  hq = Management::Branch.find_by(code: "HQ")
  general_manager_role = Management::Role.find_by(code: "general_manager")
  User.where(role: :manager).find_each do |user|
    Management::RoleAssignment.find_or_create_by!(
      user: user,
      role: general_manager_role,
      branch: hq
    )
  end
end

unless Management::ApprovalWorkflow.exists?
  loan_officer_role = Management::Role.find_by(code: "loan_officer")
  branch_manager_role = Management::Role.find_by(code: "branch_manager")
  general_manager_role = Management::Role.find_by(code: "general_manager")
  system_admin_role = Management::Role.find_by(code: "system_admin")
  board_member_role = Management::Role.find_by(code: "board_member")

  loan_approval = Management::ApprovalWorkflow.create!(
    name: "Loan Approval",
    code: "loan_approval",
    category: "lending",
    description: "Multi-tier loan approval process"
  )

  loan_approval.steps.create!([
    { sequence: 1, approver_role: loan_officer_role, threshold_cents_min: 0, threshold_cents_max: 5_000_000 },
    { sequence: 2, approver_role: branch_manager_role, threshold_cents_min: 5_000_100, threshold_cents_max: 50_000_000 },
    { sequence: 3, approver_role: general_manager_role, threshold_cents_min: 50_000_100, threshold_cents_max: nil }
  ])

  config_change = Management::ApprovalWorkflow.create!(
    name: "Configuration Change",
    code: "config_change",
    category: "system",
    description: "System configuration change approval"
  )

  config_change.steps.create!([
    { sequence: 1, approver_role: system_admin_role },
    { sequence: 2, approver_role: general_manager_role }
  ])

  policy_approval = Management::ApprovalWorkflow.create!(
    name: "Policy Approval",
    code: "policy_approval",
    category: "governance",
    description: "Policy review and approval process"
  )

  policy_approval.steps.create!([
    { sequence: 1, approver_role: general_manager_role },
    { sequence: 2, approver_role: board_member_role }
  ])
end

unless Management::AlertSubscription.exists?
  alert_types = %w[low_cash large_transaction compliance_breach system_error member_activity loan_due]
  channels = %w[email in_app dashboard]

  Management::Role.where(code: %w[general_manager system_admin]).find_each do |role|
    role.role_assignments.includes(:user).find_each do |assignment|
      alert_types.each do |alert_type|
        channels.each do |channel|
          Management::AlertSubscription.find_or_create_by!(
            user: assignment.user,
            alert_type: alert_type,
            channel: channel
          )
        end
      end
    end
  end
end

unless Management::Policy.exists?
  admin_user = User.find_by(email_address: "admin@example.com")

  max_loan = Management::Policy.create!(
    name: "Maximum Loan Amount",
    code: "max_loan_amount",
    category: "lending",
    description: "Sets the maximum loan amount based on member classification",
    status: :active,
    created_by: admin_user
  )

  max_loan.rules.create!([
    { field: "loan_amount", operator: "lte", value: "500000", effect: :allow },
    { field: "member_tier", operator: "eq", value: "regular", effect: :allow },
    { field: "loan_amount", operator: "gt", value: "500000", effect: :deny }
  ])

  teller_cash = Management::Policy.create!(
    name: "Teller Cash Limit",
    code: "teller_cash_limit",
    category: "cash_management",
    description: "Maximum cash that a teller can hold at any time",
    status: :active,
    created_by: admin_user
  )

  teller_cash.rules.create!([
    { field: "cash_on_hand", operator: "lte", value: "100000", effect: :allow },
    { field: "cash_on_hand", operator: "gt", value: "100000", effect: :deny }
  ])

  min_savings = Management::Policy.create!(
    name: "Minimum Savings Balance",
    code: "min_savings_balance",
    category: "savings",
    description: "Minimum maintaining balance for savings accounts",
    status: :active,
    created_by: admin_user
  )

  min_savings.rules.create!([
    { field: "balance", operator: "gte", value: "500", effect: :allow },
    { field: "balance", operator: "lt", value: "500", effect: :deny }
  ])
end

puts "Management module seeded:"
puts "  #{Management::Branch.count} branches"
puts "  #{Management::Department.count} departments"
puts "  #{Management::Role.count} roles"
puts "  #{Management::Permission.count} permissions"
puts "  #{Management::ApprovalWorkflow.count} approval workflows"
puts "  #{Management::Policy.count} policies"
