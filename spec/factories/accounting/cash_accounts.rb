FactoryBot.define do
  factory :accounting_cash_account, class: "Accounting::CashAccount" do
    user
    account { association :accounting_account }
  end
end