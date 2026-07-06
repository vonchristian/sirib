COOPERATIVES_COUNT = 10

puts "=" * 60
puts "SIRIB Cooperative Banking System — Seed"
puts "=" * 60

# Create cooperatives
puts "\nPhase 1: Cooperatives"
require_relative "seeds/cooperatives"

# Create users per cooperative
puts "\nPhase 2: Users"
require_relative "seeds/users"

puts "\nPhase 3: Loan aging groups"
require_relative "seeds/loan_aging_groups"

unless Rails.env.test?
  puts "\nPhase 4: Demo data"
  require_relative "seeds/demo_data"
end

unless Rails.env.test?
  puts "\nPhase 5: Sales demo comprehensive data"
  require_relative "seeds/sales_demo"
end

unless Rails.env.test?
  puts "\nPhase 6: Year-long audit trail"
  require_relative "seeds/audit_trail"
  run_year_long_audit_trail
end

puts "\nPhase 6: Security configuration"
require_relative "seeds/security"

puts ""
puts "=" * 60
puts "Seed complete"
puts "  Cooperatives: #{Cooperative.count}"
puts "  Users: #{User.count}"
puts "  Password Policies: #{Security::PasswordPolicy.count}"
puts "  Fraud Rules: #{Fraud::Rule.count}"
puts "  Compliance Controls: #{Compliance::Control.count}"
puts "=" * 60