FactoryBot.define do
  factory :security_password_history, class: 'Security::PasswordHistory' do
    user { nil }
    password_digest { "MyString" }
    created_at { "2026-06-24 08:23:04" }
  end
end
