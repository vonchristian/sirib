require "csv"

module External
  class ParseBankDocumentJob < ApplicationJob
    queue_as :default

    def perform(document)
      unless document.file.attached?
        document.update!(processing_status: :failed, error_message: "No file attached")
        return
      end

      account = document.account
      rows = parse_csv(document)

      rows.each do |row|
        next if row[:amount_cents].nil? || row[:amount_cents].zero?

        hash_signature = External::BankTransaction.generate_hash_signature(
          account_id: account.id,
          transaction_date: row[:transaction_date],
          description: row[:description],
          amount: row[:amount].to_s,
          direction: row[:direction],
          reference_number: row[:reference_number]
        )

        next if External::BankTransaction.exists?(hash_signature: hash_signature)

        External::BankTransaction.create!(
          external_bank_account_id: account.id,
          external_bank_document_id: document.id,
          transaction_date: row[:transaction_date],
          description: row[:description].to_s.strip.truncate(500),
          reference_number: row[:reference_number]&.to_s&.strip&.truncate(100),
          amount: row[:amount].abs,
          amount_cents: row[:amount_cents].abs,
          amount_currency: account.currency,
          direction: row[:direction],
          running_balance: row[:running_balance],
          running_balance_cents: row[:running_balance_cents],
          running_balance_currency: account.currency,
          hash_signature: hash_signature
        )
      end

      document.update!(processing_status: :parsed, metadata: { transaction_count: rows.count })
      account.update_balance!
    rescue => e
      document.update!(processing_status: :failed, error_message: e.message)
    end

    private

    def parse_csv(document)
      content = document.file.download
      rows = CSV.parse(content, headers: true, skip_blanks: true)

      rows.map do |row|
        {
          transaction_date: parse_date(row["date"] || row["transaction_date"] || row["posting_date"]),
          description: row["description"] || row["particulars"] || row["details"] || "",
          reference_number: row["reference"] || row["ref"] || row["reference_number"],
          amount: parse_amount(row["amount"] || row["withdrawal"] || row["deposit"]),
          amount_cents: parse_amount_cents(row["amount"] || row["withdrawal"] || row["deposit"]),
          direction: detect_direction(row["amount"] || row["withdrawal"] || row["deposit"], row["type"]),
          running_balance: parse_amount(row["running_balance"] || row["balance"]),
          running_balance_cents: parse_amount_cents(row["running_balance"] || row["balance"])
        }
      end.compact
    end

    def parse_date(value)
      return nil unless value

      date_formats = ["%Y-%m-%d", "%m/%d/%Y", "%d/%m/%Y", "%m-%d-%Y", "%d-%m-%Y", "%B %d, %Y"]
      date_formats.each do |format|
        begin
          return Date.strptime(value.to_s.strip, format)
        rescue Date::ParseError
          next
        end
      end
      Date.parse(value.to_s)
    rescue
      nil
    end

    def parse_amount(value)
      return nil unless value

      value.to_s.gsub(/[^0-9.-]/, "").to_d
    end

    def parse_amount_cents(value)
      amount = parse_amount(value)
      return nil unless amount

      (amount * 100).round
    end

    def detect_direction(amount_str, type_str)
      type = type_str&.downcase
      return "credit" if type&.include?("credit") || type&.include?("deposit")
      return "debit" if type&.include?("debit") || type&.include?("withdrawal")

      amount = parse_amount(amount_str)
      return "credit" if amount.present? && amount > 0
      return "debit" if amount.present? && amount < 0

      "credit"
    end
  end
end