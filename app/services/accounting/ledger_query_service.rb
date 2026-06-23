module Accounting
  class LedgerQueryService
    attr_reader :account, :filters, :sort_order

    def initialize(account:, filters: {}, sort_order: "desc")
      @account = account
      @filters = filters
      @sort_order = sort_order
    end

    def scope
      s = Accounting::AmountLine
        .joins(:entry)
        .includes(entry: :created_by)
        .where(account_id: account.id)

      if filters[:from_date].present?
        s = s.where(entries: { posted_at: filters[:from_date].beginning_of_day.. })
      end

      if filters[:to_date].present?
        s = s.where(entries: { posted_at: ..filters[:to_date].end_of_day })
      end

      if filters[:debit_only].present? && filters[:debit_only] == "1"
        s = s.where(amount_type: :debit)
      end

      if filters[:credit_only].present? && filters[:credit_only] == "1"
        s = s.where(amount_type: :credit)
      end

      if filters[:amount_min].present?
        s = s.where("amount_cents >= ?", (filters[:amount_min].to_f * 100).to_i)
      end

      if filters[:amount_max].present?
        s = s.where("amount_cents <= ?", (filters[:amount_max].to_f * 100).to_i)
      end

      if filters[:reference_number].present?
        s = s.where("entries.reference_number ILIKE ?", "%#{filters[:reference_number]}%")
      end

      if filters[:description].present?
        s = s.where("entries.description ILIKE ?", "%#{filters[:description]}%")
      end

      if filters[:entry_type].present?
        s = s.where(entries: { entry_type: filters[:entry_type] })
      end

      if filters[:source_module].present?
        s = s.where(entries: { source_module: filters[:source_module] })
      end

      direction = sort_order.downcase == "asc" ? :asc : :desc
      s.order("entries.posted_at #{direction}", "entries.id #{direction}", id: direction)
    end

    def build_ledger_lines(amount_lines)
      return [] if amount_lines.empty?

      normal_debit_increases = !account.normal_credit_balance? ^ account.contra

      opening = if filters[:from_date].present?
        account.balance(to_date: filters[:from_date] - 1.day)
      else
        Money.new(0, "PHP")
      end

      lines = if sort_order.downcase == "asc"
        amount_lines_sorted = amount_lines.sort_by { |al| [ al.entry.posted_at, al.entry.id ] }
        compute_lines(amount_lines_sorted, opening.cents, normal_debit_increases)
      else
        amount_lines_sorted = amount_lines.sort_by { |al| [ al.entry.posted_at, al.entry.id ] }.reverse
        compute_lines(amount_lines_sorted, opening.cents, normal_debit_increases).reverse
      end

      lines
    end

    def compute_lines(amount_lines_asc, opening_cents, normal_debit_increases)
      running = opening_cents

      amount_lines_asc.map do |al|
        signed = al.debit? ? al.amount_cents : -al.amount_cents
        if normal_debit_increases
          running += signed
        else
          running -= signed
        end

        LedgerLine.new(
          date: al.entry.posted_at,
          journal_entry_id: al.entry.id,
          entry_number: al.entry.reference_number,
          memo: al.entry.description,
          debit: al.debit? ? Money.new(al.amount_cents, "PHP") : Money.new(0, "PHP"),
          credit: al.credit? ? Money.new(al.amount_cents, "PHP") : Money.new(0, "PHP"),
          running_balance: Money.new(running, "PHP"),
          posted_by: al.entry.created_by&.email_address&.split("@")&.first || "System",
          source_type: al.entry.entry_type&.titleize,
          status: al.entry.status,
          branch: al.entry.branch&.name,
          entry_type: al.entry.entry_type,
          source_module: al.entry.source_module
        )
      end
    end

    def summary
      s = Accounting::AmountLine
        .joins(:entry)
        .where(account_id: account.id)

      if filters[:from_date].present?
        s = s.where(entries: { posted_at: filters[:from_date].beginning_of_day.. })
      end

      if filters[:to_date].present?
        s = s.where(entries: { posted_at: ..filters[:to_date].end_of_day })
      end

      totals = s.group(:amount_type).sum(:amount_cents)

      total_debits = Money.new(totals[0] || totals["debit"] || 0, "PHP")
      total_credits = Money.new(totals[1] || totals["credit"] || 0, "PHP")

      normal_debit_increases = !account.normal_credit_balance? ^ account.contra

      net_movement = if normal_debit_increases
        total_debits - total_credits
      else
        total_credits - total_debits
      end

      if filters[:from_date].present?
        opening = account.balance(to_date: filters[:from_date] - 1.day)
      else
        opening = Money.new(0, "PHP")
      end

      current_balance = opening + net_movement

      {
        opening: opening,
        total_debits: total_debits,
        total_credits: total_credits,
        net_movement: net_movement,
        current_balance: current_balance
      }
    end

    private
  end

  LedgerLine = Struct.new(
    :date, :journal_entry_id, :entry_number, :memo,
    :debit, :credit, :running_balance, :posted_by,
    :source_type, :status, :branch, :entry_type, :source_module,
    keyword_init: true
  )
end
