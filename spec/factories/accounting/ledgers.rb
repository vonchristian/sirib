FactoryBot.define do
  factory :accounting_ledger, class: "Accounting::Ledger" do
    name { Faker::Commerce.department }
    account_code { Faker::Alphanumeric.alpha(number: 8).upcase }
    account_type { "asset" }
    contra { false }
  end
end
