FactoryBot.define do
  factory :idempotency_key do
    key { SecureRandom.uuid }
    cooperative
    service { "TestService" }
    expires_at { 24.hours.from_now }
    resource { nil }
  end
end
