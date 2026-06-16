FactoryBot.define do
  factory :member_identification do
    member
    id_type { "BIR" }
    id_number { "BIR-#{Faker::Number.unique.number(digits: 9)}" }
  end
end
