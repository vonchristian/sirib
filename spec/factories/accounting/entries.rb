FactoryBot.define do
  factory :accounting_entry, class: "Accounting::Entry" do
    description { Faker::Lorem.sentence }
    reference_number { "ENT-#{Faker::Alphanumeric.alpha(number: 12).upcase}" }
    posted_at { Time.zone.now }
  end
end
