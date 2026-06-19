FactoryBot.define do
  factory :portal_session, class: "Portal::Session" do
    association :member, factory: :member
    ip_address { "192.168.1.1" }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" }
    last_activity_at { Time.current }
    mfa_verified_at { nil }
  end
end