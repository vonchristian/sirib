FactoryBot.define do
  factory :compliance_evidence, class: 'Compliance::Evidence' do
    control { nil }
    status { "MyString" }
    evidence_type { "MyString" }
    metadata { "" }
    verified_at { "2026-06-24 08:23:08" }
    verified_by { nil }
    expires_at { "2026-06-24 08:23:08" }
    cooperative { nil }
  end
end
