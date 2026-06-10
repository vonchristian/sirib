FactoryBot.define do
  factory :accounting_account, class: "Accounting::Account" do
    ledger { association :accounting_ledger }
    name { Faker::Lorem.word }
    account_code { Faker::Alphanumeric.alpha(number: 8).upcase }
    account_type { "asset" }
    contra { false }
  end
end
