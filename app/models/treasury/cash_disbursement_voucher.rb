module Treasury
  class CashDisbursementVoucher < Voucher
    def post_entry!(debit_account:)
      validate_posting!
      entry = Accounting::PostEntryService.run!(
        description: description || "Cash disbursement: #{category}",
        reference_number: "JE-#{voucher_number}",
        posted_at: Time.current,
        debits: [{ account: debit_account, amount: amount_cents }],
        credits: [{ account: cash_account, amount: amount_cents }]
      )
      update!(entry: entry, status: "posted", posted_at: Time.current)
      entry
    end
  end
end
