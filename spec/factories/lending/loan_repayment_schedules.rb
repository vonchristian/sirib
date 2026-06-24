FactoryBot.define do
  factory :lending_loan_repayment_schedule, class: "Lending::LoanRepaymentSchedule" do
    cooperative
    association :loan_application, factory: :lending_loan_application
    add_attribute(:sequence) { 1 }
    due_date { Date.current.next_month }
    principal_cents { 8_333_33 }
    interest_cents { 1_250_00 }
  end
end
