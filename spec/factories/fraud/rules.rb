FactoryBot.define do
  factory :fraud_rule, class: 'Fraud::Rule' do
    name { "MyString" }
    description { "MyText" }
    rule_type { "MyString" }
    config { "" }
    severity { "MyString" }
    active { false }
    cooperative { nil }
  end
end
