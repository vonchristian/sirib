FactoryBot.define do
  factory :time_deposit, class: "Treasury::TimeDeposit" do
    depositor { association :user, password: "secret123" }
    time_deposit_product
    amount_cents { 10_000_00 }
    interest_rate { time_deposit_product.interest_rate }
    interest_earned_cents { (amount_cents * interest_rate * time_deposit_product.term_in_days / 365.0).round }
    matured_on { time_deposit_product.term_in_days.days.from_now.to_date }
    opened_at { Time.current }
    status { "active" }
  end
end
