FactoryBot.define do
  factory :external_bank_document, class: "External::BankDocument" do
    account { association :external_bank_account }
    document_type { "statement" }
    period_start { 1.month.ago.to_date }
    period_end { Date.current }
    processing_status { "pending" }
  end
end
