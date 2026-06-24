FactoryBot.define do
  factory :lending_loan_schedule, class: "Lending::LoanSchedule" do
    loan factory: :lending_loan
    cooperative
    version { 1 }
    status { "active" }
    schedule_data { [ { "sequence" => 1, "due_date" => Date.current.next_month.to_s, "principal_cents" => 8333_33, "interest_cents" => 1250_00 } ] }
  end
end
