FactoryBot.define do
  factory :lending_loan_aging, class: "Lending::LoanAging" do
    cooperative
    association :loan, factory: :lending_loan
    association :loan_aging_group, factory: :lending_loan_aging_group
    days_past_due { 0 }
    oldest_unpaid_due_date { nil }
    outstanding_principal_cents { 0 }
    outstanding_interest_cents { 0 }
    penalty_amount_cents { 0 }
    total_exposure_cents { 0 }
    calculated_at { Time.current }
  end
end
