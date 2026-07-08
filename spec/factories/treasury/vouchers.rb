FactoryBot.define do
  factory :voucher, class: "Treasury::Voucher" do
    # Create simple instance with all required attributes but bypassing associations for now
    amount_cents { 10000 }
    category { "test_category" }
    status { "pending" }
    voucher_number { "CRV-20230101-ABCDEF" }

    trait :receipt do
      type { "Treasury::CashReceiptVoucher" }
    end

    trait :disbursement do
      type { "Treasury::CashDisbursementVoucher" }
    end

    factory :cash_receipt_voucher, traits: [ :receipt ]
    factory :cash_disbursement_voucher, traits: [ :disbursement ]
  end
end
