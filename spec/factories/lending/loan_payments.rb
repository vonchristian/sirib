FactoryBot.define do
  factory :lending_loan_payment, class: "Lending::LoanPayment" do
    cooperative
    association :loan, factory: :lending_loan
    amount_cents { 11_250_00 }
    principal_cents { 10_000_00 }
    interest_cents { 1_250_00 }
    penalty_cents { 0 }
    payment_date { Date.current }
  end
end
