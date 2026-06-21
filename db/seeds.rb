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

unless Rails.env.test?
  puts "\nPhase 3: Demo data"
  require_relative "seeds/demo_data"
end

puts ""
puts "=" * 60
puts "Seed complete"
puts "  Cooperatives: #{Cooperative.count}"
puts "  Users: #{User.count}"
puts "=" * 60