module Accounting
  class JournalReportService
    def initialize(start_date:, end_date:, branch_id: nil, account_id: nil, report_type: :trial_balance)
      @start_date = start_date
      @end_date = end_date
      @branch_id = branch_id
      @account_id = account_id
      @report_type = report_type
    end

    def call
      case report_type
      when :trial_balance
        generate_trial_balance
      when :general_ledger
        generate_general_ledger
      when :journal_summary
        generate_journal_summary
      when :reversal_report
        generate_reversal_report
      when :adjustment_report
        generate_adjustment_report
      else
        raise ArgumentError, "Unknown report type: #{report_type}"
      end
    end

    def to_csv
      data = call
      CSV.generate(headers: true) do |csv|
        csv << data[:headers]
        data[:rows].each do |row|
          csv << row
        end
      end
    end

    def to_pdf
      data = call
      PDFGenerator.new(report_type: report_type, data: data, date_range: date_range).generate
    end

    private

    attr_reader :start_date, :end_date, :branch_id, :account_id, :report_type

    def date_range
      { start_date: start_date, end_date: end_date }
    end

    def base_scope
      scope = Accounting::Entry.posted.date_range(start_date, end_date)
      scope = scope.by_branch(branch_id) if branch_id.present?
      scope = scope.by_account(account_id) if account_id.present?
      scope
    end

    def generate_trial_balance
      accounts_scope = Accounting::Account.all
      accounts_scope = accounts_scope.joins(:ledger).where(accounting_ledgers: { branch_id: branch_id }) if branch_id.present?

      accounts = accounts_scope.order(:account_code).to_a

      debits = []
      credits = []
      total_debits = 0
      total_credits = 0

      accounts.each do |account|
        balance = account.balance(to_date: end_date)
        next if balance.zero?

        if account.normal_credit_balance?
          credits << { account: account.account_code, name: account.name, amount: balance }
          total_credits += balance.cents
        else
          debits << { account: account.account_code, name: account.name, amount: balance }
          total_debits += balance.cents
        end
      end

      {
        title: "Trial Balance",
        date_range: date_range,
        headers: ["Account", "Name", "Debit", "Credit"],
        rows: build_trial_balance_rows(debits, credits),
        totals: { debits: total_debits, credits: total_credits },
        balanced: total_debits == total_credits
      }
    end

    def build_trial_balance_rows(debits, credits)
      rows = []
      max_rows = [debits.size, credits.size].max

      max_rows.times do |i|
        debit_row = debits[i] || { account: "", name: "", amount: 0 }
        credit_row = credits[i] || { account: "", name: "", amount: 0 }

        rows << [
          debit_row[:account],
          debit_row[:name],
          debit_row[:amount].zero? ? "" : debit_row[:amount].format,
          credit_row[:amount].zero? ? "" : credit_row[:amount].format
        ]
      end

      rows
    end

    def generate_general_ledger
      scope = base_scope.preload(:amount_lines, :branch, :created_by)

      entries = scope.order(posted_at: :asc).to_a
      grouped = entries.group_by(&:account_id)

      accounts_data = []
      grand_total_debits = 0
      grand_total_credits = 0

      if account_id.present?
        account = Accounting::Account.find(account_id)
        account_entries = Accounting::Entry.by_account(account_id)
                                          .posted
                                          .date_range(start_date, end_date)
                                          .order(posted_at: :asc)
                                          .preload(:amount_lines)

        entries_data = account_entries.map do |entry|
          debit = entry.amount_lines.debit.sum(&:amount_cents)
          credit = entry.amount_lines.credit.sum(&:amount_cents)
          grand_total_debits += debit
          grand_total_credits += credit

          {
            date: entry.posted_at,
            reference: entry.reference_number,
            description: entry.description,
            debit: debit,
            credit: credit,
            balance: calculate_running_balance(account, entry.posted_at)
          }
        end

        accounts_data << {
          account_code: account.account_code,
          account_name: account.name,
          entries: entries_data,
          total_debits: grand_total_debits,
          total_credits: grand_total_credits
        }
      else
        Accounting::Account.order(:account_code).each do |account|
          account_entries = account.entries.posted.date_range(start_date, end_date).order(posted_at: :asc).to_a
          next if account_entries.empty?

          entries_data = []
          total_debit = 0
          total_credit = 0

          account_entries.each do |entry|
            debit = entry.amount_lines.debit.sum(&:amount_cents)
            credit = entry.amount_lines.credit.sum(&:amount_cents)
            total_debit += debit
            total_credit += credit

            entries_data << {
              date: entry.posted_at,
              reference: entry.reference_number,
              description: entry.description,
              debit: debit,
              credit: credit
            }
          end

          grand_total_debits += total_debit
          grand_total_credits += total_credit

          accounts_data << {
            account_code: account.account_code,
            account_name: account.name,
            entries: entries_data,
            total_debits: total_debit,
            total_credits: total_credit
          }
        end
      end

      {
        title: "General Ledger",
        date_range: date_range,
        accounts: accounts_data,
        grand_totals: { debits: grand_total_debits, credits: grand_total_credits }
      }
    end

    def generate_journal_summary
      entries = base_scope.preload(:amount_lines, :branch, :created_by).to_a

      by_date = entries.group_by { |e| e.posted_at.to_date }

      rows = []
      by_date.each do |date, day_entries|
        day_entries.each do |entry|
          rows << {
            date: date,
            reference: entry.reference_number,
            description: entry.description,
            branch: entry.branch&.name,
            entry_type: entry.entry_type,
            source: entry.source_module,
            status: entry.status,
            total: entry.net_amount,
            created_by: entry.created_by&.name || "System"
          }
        end
      end

      {
        title: "Journal Summary",
        date_range: date_range,
        headers: ["Date", "Reference", "Description", "Branch", "Type", "Source", "Status", "Amount", "Created By"],
        rows: rows.map { |r| [r[:date], r[:reference], r[:description], r[:branch], r[:entry_type], r[:source], r[:status], r[:total].format, r[:created_by]] },
        total_entries: entries.size,
        total_amount: entries.sum(&:net_amount)
      }
    end

    def generate_reversal_report
      scope = base_scope.where(entry_type: :reversal_entry).order(posted_at: :desc)

      {
        title: "Reversal Report",
        date_range: date_range,
        headers: ["Date", "Reference", "Original Entry", "Reversed By", "Reason", "Amount"],
        rows: scope.map do |entry|
          original = entry.reversal_of
          [
            entry.posted_at.to_date,
            entry.reference_number,
            original&.reference_number || "N/A",
            entry.reference_number,
            entry.description,
            entry.net_amount.format
          ]
        end
      }
    end

    def generate_adjustment_report
      scope = base_scope.where(entry_type: :adjustment_entry).order(posted_at: :desc)

      {
        title: "Adjustment Report",
        date_range: date_range,
        headers: ["Date", "Reference", "Description", "Branch", "Status", "Amount", "Created By"],
        rows: scope.map do |entry|
          [
            entry.posted_at.to_date,
            entry.reference_number,
            entry.description,
            entry.branch&.name || "N/A",
            entry.status,
            entry.net_amount.format,
            entry.created_by&.name || "System"
          ]
        end
      }
    end

    def calculate_running_balance(account, to_date)
      account.balance(to_date: to_date)
    end
  end
end