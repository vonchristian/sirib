module Treasury
  class CashReceiptVoucher < Voucher
    include CooperativeScoped

    def post_entry!(credit_account:)
      validate_posting!
      entry = Accounting::PostEntryService.run!(
        description: description || "Cash receipt: #{category}",
        reference_number: "JE-#{voucher_number}",
        posted_at: Time.current,
        debits: [{ account: cash_account, amount: amount_cents }],
        credits: [{ account: credit_account, amount: amount_cents }]
      )
      update!(entry: entry, status: "posted", posted_at: Time.current)
      entry
    end
  end
end
