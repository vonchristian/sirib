FactoryBot.define do
  sequence(:loan_reference_number) { |n| "LN-TEST-#{n.to_s.rjust(6, '0')}" }

  factory :lending_loan, class: "Lending::Loan" do
    cooperative
    association :loan_application, factory: :lending_loan_application
    association :member, factory: :member
    association :loan_product, factory: :lending_loan_product
    principal_cents { 100_000_00 }
    interest_rate { 1.5 }
    interest_calculation { "declining_balance" }
    term_months { 12 }
    outstanding_principal_cents { 100_000_00 }
    status { "active" }
    reference_number { generate(:loan_reference_number) }
  end
end
