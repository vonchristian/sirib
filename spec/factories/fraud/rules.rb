FactoryBot.define do
  factory :fraud_rule, class: 'Fraud::Rule' do
    sequence(:name) { |n| "Fraud Rule #{n}" }
    description { "Fraud detection rule" }
    rule_type { "large_amount" }
    config { {} }
    severity { "medium" }
    active { true }
    cooperative
  end
end
