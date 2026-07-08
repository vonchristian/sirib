puts "\n=== Creating Users ==="

USER_ROSTER = {
  admin:       { role: :manager,     full_name: "System Administrator" },
  manager:     { role: :manager,     full_name: "General Manager" },
  loan_officer: { role: :loan_officer, full_name: "Loan Officer" },
  teller:      { role: :treasurer,   full_name: "Teller" },
  accountant:  { role: :accountant,  full_name: "Accountant" },
  auditor:     { role: :accountant,  full_name: "Auditor" }
}

total = 0
Cooperative.active.order(:name).find_each do |coop|
  subdomain_key = coop.name.parameterize

  USER_ROSTER.each do |role_key, attrs|
    email = "#{role_key}_#{subdomain_key}@sirib.ph"
    next if User.exists?(email_address: email)

    User.create!(
      email_address: email,
      password: "password123",
      role: attrs[:role],
      full_name: attrs[:full_name],
      status: "active",
      cooperative: coop
    )
    total += 1
  end
end

puts "  → #{total} users created across #{Cooperative.active.count} cooperatives"
