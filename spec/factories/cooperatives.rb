FactoryBot.define do
  factory :cooperative do
    sequence(:name) { |n| "Cooperative #{n}" }
    sequence(:schema_name) { |n| "tenant_cooperative_#{n}" }
    sequence(:subdomain) { |n| "coop-#{n}" }
    status { "active" }
  end
end
