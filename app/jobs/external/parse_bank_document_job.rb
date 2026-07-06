require "csv"

module External
  class ParseBankDocumentJob < ApplicationJob
    queue_as :bank_parsing

    DATE_PATTERNS = [
      /\b\d{4}-\d{2}-\d{2}\b/,                   # 2025-01-15
      /\b\d{2}\/\d{2}\/\d{4}\b/,                  # 01/15/2025
      /\b\d{2}-\d{2}-\d{4}\b/,                    # 01-15-2025
      /\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4}\b/i,
      /\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\b/i
    ].freeze

    AMOUNT_RE = /(?:PHP|₱|Php)?\s*[+-]?(?:\d{1,3}(?:,\d{3})*|\d+)\.\d{2}\b/

    def perform(document)
      unless document.file.attached?
        document.update!(processing_status: :failed, error_message: "No file attached")
        return
      end

      account = document.account
      rows = if pdf_file?(document)
        parse_pdf(document)
      else
        parse_csv(document)
      end

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
          amount_cents: row[:amount_cents].abs,
          amount_currency: account.currency,
          direction: row[:direction],
          running_balance_cents: row[:running_balance_cents],
          running_balance_currency: account.currency,
          hash_signature: hash_signature
        )
      end

      document.update!(processing_status: :parsed, metadata: { transaction_count: rows.count, format: rows.first&.dig(:format) || :csv })
      account.update_balance!
    rescue => e
      document.update!(processing_status: :failed, error_message: e.message)
    end

    private

    def pdf_file?(document)
      content_type = document.file.content_type
      return true if content_type == "application/pdf"
      File.extname(document.file.filename.to_s).downcase == ".pdf"
    end

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

    def parse_pdf(document)
      require "pdf-reader"

      content = document.file.download
      reader = PDF::Reader.new(StringIO.new(content))
      text = reader.pages.map(&:text).join("\n")
      lines = text.split("\n").map(&:strip).reject(&:empty?)

      rows = []
      pending_desc = nil

      lines.each do |line|
        date_start = find_date_at_start(line)

        if date_start
          row = build_row_from_line(date_start[:line], date_start[:date])

          if row
            if pending_desc
              row[:description] = "#{pending_desc} #{row[:description]}".strip
              pending_desc = nil
            end
            rows << row
          else
            pending_desc = [ pending_desc, line ].compact.join(" ")
          end
        else
          pending_desc = [ pending_desc, line ].compact.join(" ")
        end
      end

      rows
    end

    def find_date_at_start(line)
      DATE_PATTERNS.each do |pattern|
        match = line.match(pattern)
        next unless match
        return { date: parse_date(match[0]), line: line } if match.pre_match.strip.empty?
      end
      nil
    end

    def build_row_from_line(line, date)
      amounts = line.scan(AMOUNT_RE).map { |s| parse_amount(s) }.compact
      amounts.reject! { |a| a == 0 }
      return nil if amounts.empty?

      balance = amounts.pop
      transaction_amount = amounts.last || balance

      direction = if line.match?(/\bDR\b/i)
        "debit"
      elsif line.match?(/\bCR\b/i)
        "credit"
      elsif transaction_amount < 0
        "debit"
      else
        "credit"
      end

      description = extract_description(line, date)

      {
        transaction_date: date,
        description: description,
        reference_number: nil,
        amount: transaction_amount.abs,
        amount_cents: (transaction_amount.abs * 100).round,
        direction: direction,
        running_balance: balance,
        running_balance_cents: (balance * 100).round,
        format: :pdf
      }
    end

    def extract_description(line, date)
      rest = line.dup
      DATE_PATTERNS.each do |pattern|
        rest = rest.sub(pattern, "")
      end
      rest.gsub!(AMOUNT_RE, "")
      rest.gsub!(/\b(?:DR|CR)\b/i, "")
      rest.gsub!(/(?:PHP|₱|Php)/, "")
      rest.strip.gsub(/\s+/, " ").strip
    end

    def parse_date(value)
      return nil unless value

      date_formats = [
        "%Y-%m-%d", "%m/%d/%Y", "%d/%m/%Y", "%m-%d-%Y", "%d-%m-%Y",
        "%B %d, %Y", "%b %d, %Y", "%b %d %Y", "%d %b %Y",
        "%m/%d/%y", "%m-%d-%y"
      ]
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
      value.to_s.gsub(/[^0-9.\-]/, "").to_d
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
