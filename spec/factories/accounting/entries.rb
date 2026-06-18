FactoryBot.define do
  sequence(:entry_reference_number) { |n| "ENT-#{Time.current.strftime("%Y%m%d-%H%M%S")}-#{n}#{SecureRandom.hex(2).upcase}" }

  factory :accounting_entry, class: "Accounting::Entry" do
    description { Faker::Lorem.sentence }
    reference_number { generate(:entry_reference_number) }
    posted_at { Time.zone.now }

    # Use after_create instead to properly build the associated records
    after(:create) do |entry|
      account = create(:accounting_account)
      create(:accounting_amount_line, entry:, account:, amount_type: "debit", amount_cents: 1000, amount_currency: "PHP")
      create(:accounting_amount_line, entry:, account:, amount_type: "credit", amount_cents: 1000, amount_currency: "PHP")
    end
  end
end
