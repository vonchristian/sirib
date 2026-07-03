FactoryBot.define do
  sequence(:loan_app_reference_number) { |n| "LA-TEST-#{n.to_s.rjust(6, '0')}" }
  sequence(:uuid) { |n| SecureRandom.uuid }

  factory :lending_loan_application, class: "Lending::LoanApplication" do
    cooperative
    association :member, factory: :member
    association :loan_product, factory: :lending_loan_product
    uuid { generate(:uuid) }
    status { "approved" }
    current_step { 5 }
    amount_cents { 100_000_00 }
    interest_rate { 1.5 }
    term_months { 12 }
    submitted_at { Time.current }
    approved_at { Time.current }
    reference_number { generate(:loan_app_reference_number) }
  end
end
