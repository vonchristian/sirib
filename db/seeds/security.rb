puts "  Seeding security configuration..."

Cooperative.active.order(:name).each do |coop|
  puts "    Cooperative: #{coop.name}"

  Security::PasswordPolicy.find_or_create_by!(
    name: "Default Policy",
    cooperative: coop
  ) do |p|
    p.min_length = 8
    p.require_uppercase = true
    p.require_lowercase = true
    p.require_digits = true
    p.require_symbols = false
    p.max_failed_attempts = 10
    p.lockout_duration = 30
    p.password_expiry_days = 90
    p.password_history_count = 5
    p.active = true
    puts "      Created default password policy"
  end
end

puts "  Security seeding complete."
