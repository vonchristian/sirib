FactoryBot.define do
  factory :portal_enrollment_token, class: "Portal::EnrollmentToken" do
    association :member, factory: :member
    token { SecureRandom.hex(24) }
    expires_at { 48.hours.from_now }
  end
end