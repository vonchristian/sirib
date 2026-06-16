FactoryBot.define do
  factory :savings_transaction, class: "Treasury::SavingsTransaction" do
    savings_account
    transaction_type { :deposit }
    amount_cents { 500000 }
    amount_currency { "PHP" }
    association :cash_account, factory: :accounting_account
    notes { "Test transaction" }
    status { "completed" }
    posted_at { Time.current }
  end
end
