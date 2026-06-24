FactoryBot.define do
  factory :security_password_policy, class: 'Security::PasswordPolicy' do
    name { "MyString" }
    min_length { 1 }
    require_uppercase { false }
    require_lowercase { false }
    require_digits { false }
    require_symbols { false }
    max_failed_attempts { 1 }
    lockout_duration { 1 }
    password_expiry_days { 1 }
    password_history_count { 1 }
    cooperative { nil }
    active { false }
  end
end
