FactoryBot.define do
  factory :lending_loan_aging_snapshot, class: "Lending::LoanAgingSnapshot" do
    cooperative
    association :loan_aging_group, factory: :lending_loan_aging_group
    snapshot_date { Date.current }
    loan_count { 0 }
    member_count { 0 }
    principal_amount_cents { 0 }
    interest_amount_cents { 0 }
    total_exposure_cents { 0 }
  end
end
