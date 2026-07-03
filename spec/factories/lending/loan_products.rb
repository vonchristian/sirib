FactoryBot.define do
  sequence(:loan_product_name) { |n| "Loan Product #{n}" }

  factory :lending_loan_product, class: "Lending::LoanProduct" do
    cooperative
    name { generate(:loan_product_name) }
    interest_rate { 1.5 }
    interest_calculation { "declining_balance" }
    max_term_months { 24 }
    status { "active" }
  end
end
