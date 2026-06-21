FactoryBot.define do
  factory :cooperative do
    sequence(:name) { |n| "Cooperative #{n}" }
    status { "active" }
  end
end
