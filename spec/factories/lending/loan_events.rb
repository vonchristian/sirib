FactoryBot.define do
  factory :lending_loan_event, class: "Lending::LoanEvent" do
    loan factory: :lending_loan
    cooperative
    association :actor, factory: :user
    event_type { "restructure_requested" }
    status { "completed" }
    metadata { {} }
  end
end
