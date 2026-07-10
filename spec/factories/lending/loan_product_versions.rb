FactoryBot.define do
  factory :lending_loan_product_version, class: "Lending::LoanProductVersion" do
    association :loan_product, factory: :lending_loan_product
    version { 1 }
    snapshot { {} }
  end
end
