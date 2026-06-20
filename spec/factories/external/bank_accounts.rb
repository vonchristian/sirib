FactoryBot.define do
  factory :external_bank_account, class: "External::BankAccount" do
    bank { association :external_bank }
    account_name { "Operating Account" }
    account_number_encrypted { SecureRandom.hex(8) }
    account_type { "checking" }
    currency { "PHP" }
    current_balance_cents { 0 }
    status { "active" }
  end
end