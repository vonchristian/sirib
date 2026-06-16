FactoryBot.define do
  factory :time_deposit_product, class: "Treasury::TimeDepositProduct" do
    name { "30-Day Time Deposit" }
    minimum_deposit_cents { 5_000_00 }
    interest_rate { 0.0350 }
    term_in_days { 30 }
    status { "active" }
  end
end
