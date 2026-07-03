FactoryBot.define do
  factory :lending_loan_aging_group, class: "Lending::LoanAgingGroup" do
    cooperative
    sequence(:name) { |n| "Aging Group #{n}" }
    min_days { 0 }
    max_days { 0 }
    display_order { 0 }
    active { true }
  end
end
