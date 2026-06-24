FactoryBot.define do
  factory :fraud_incident, class: 'Fraud::Incident' do
    rule { nil }
    incident_type { "MyString" }
    severity { "MyString" }
    description { "MyText" }
    metadata { "" }
    actor { nil }
    resolved_at { "2026-06-24 08:23:07" }
    resolved_by { nil }
    resolution { "MyString" }
    cooperative { nil }
  end
end
