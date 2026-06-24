FactoryBot.define do
  factory :lending_loan_restructure_case, class: "Lending::LoanRestructureCase" do
    loan factory: :lending_loan
    cooperative
    restructure_type { "modification" }
    status { "draft" }
    proposed_changes { { "interest_rate" => "1.0", "term_months" => "18" } }
    notes { "Test restructure case" }
  end
end
