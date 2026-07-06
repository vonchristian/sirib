FactoryBot.define do
  factory :external_bank_transaction, class: "External::BankTransaction" do
    account { association :external_bank_account }
    transaction_date { Date.current }
    description { "Test transaction" }
    reference_number { "REF-#{SecureRandom.hex(4).upcase}" }
    amount_cents { 1000_00 }
    amount_currency { "PHP" }
    direction { "credit" }
    running_balance_cents { 1000_00 }
    running_balance_currency { "PHP" }
    hash_signature { SecureRandom.hex(32) }
  end
end
