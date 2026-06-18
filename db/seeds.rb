require_relative "seeds/chart_of_accounts"
require_relative "seeds/sample_entries"
require_relative "seeds/members"
require_relative "seeds/loan_products"
require_relative "seeds/savings_products"
require_relative "seeds/users"
require_relative "seeds/cooperative"
require_relative "seeds/management" if defined?(Management)
require_relative "seeds/demo_data" if defined?(Management) && Management::Branch.exists? && !Rails.env.test?