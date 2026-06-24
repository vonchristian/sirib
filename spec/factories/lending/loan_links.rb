FactoryBot.define do
  factory :lending_loan_link, class: "Lending::LoanLink" do
    association :from_loan, factory: :lending_loan
    association :to_loan, factory: :lending_loan
    cooperative
    link_type { "refinance" }
    amount_cents { 0 }
    reason { "Test link" }
  end
end
