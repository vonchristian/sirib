FactoryBot.define do
  factory :external_bank_transaction_allocation, class: "External::BankTransactionAllocation" do
    bank_transaction { association :external_bank_transaction }
    allocated_amount_cents { 1000_00 }
    allocated_amount { 1000.0 }
    allocated_amount_currency { "PHP" }
    status { "suggested" }
    created_by { association :user }
  end
end