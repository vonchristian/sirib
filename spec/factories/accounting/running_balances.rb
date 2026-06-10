FactoryBot.define do
  factory :accounting_running_balance, class: "Accounting::RunningBalance" do
    account { create(:accounting_account) }
    ledger { account&.ledger }
    as_of_date { Date.current }
    balance_cents { 0 }
    balance_currency { "PHP" }
  end
end
