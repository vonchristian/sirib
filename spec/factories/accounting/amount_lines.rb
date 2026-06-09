FactoryBot.define do
  factory :accounting_amount_line, class: "Accounting::AmountLine" do
    entry { association :accounting_entry }
    account { association :accounting_account }
    amount_type { "debit" }
    amount_cents { 1000 }
    amount_currency { "PHP" }
  end
end
