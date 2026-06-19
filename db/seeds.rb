COOPERATIVES_COUNT = 10

puts "=" * 60
puts "SIRIB Cooperative Banking System — Seed"
puts "=" * 60

# Seed shared data in public schema
puts "\nPhase 1: Shared schema (public)"
require_relative "seeds/chart_of_accounts"

# Provision tenant schemas
puts "\nPhase 2: Tenant schemas"
require_relative "seeds/cooperatives"

# Create users per cooperative
puts "\nPhase 3: Users"
require_relative "seeds/users"

if !Rails.env.test?
  puts "\nPhase 4: Demo data per cooperative"
  require_relative "seeds/demo_data"
  require_relative "seeds/demo_rich_data" if Cooperative.provisioned.count < 3
end

puts ""
puts "=" * 60
puts "Seed complete"
puts "  Cooperatives: #{Cooperative.count}"
puts "  Users: #{User.count}"
puts "=" * 60
