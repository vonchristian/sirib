FactoryBot.define do
  sequence(:email_address) { |n| "user#{n}@example.com" }

  factory :user do
    email_address
    password { "password123" }
  end
end
