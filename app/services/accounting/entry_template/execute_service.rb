module Accounting
  class EntryTemplate
    class ExecuteService < ActiveInteraction::Base
      object :template, class: Accounting::EntryTemplate
      decimal :amount, default: nil
      boolean :posting, default: false
      object :user, class: User, default: nil

      validate :template_must_be_valid
      validate :amount_must_be_positive, if: :posting?

      def execute
        return preview_entries unless posting?

        entry = nil
        Accounting::Entry.transaction do
          entry = build_entry
          entry.save!
          update_running_balances!(entry)
          template.update!(entry: entry)
          entry
        end
        entry
      end

      private

      def template_must_be_valid
        result = ValidateService.run(template: template)
        return if result.valid?

        result.errors.each { |e| errors.import(e) }
      end

      def amount_must_be_positive
        errors.add(:amount, "must be greater than 0") if amount.nil? || amount <= 0
      end

      def preview_entries
        lines.map do |line|
          {
            account: line.account,
            direction: line.direction,
            amount_cents: line_amount_cents(line),
            amount_mode: line.amount_mode
          }
        end
      end

      def build_entry
        Accounting::Entry.build(
          description: "#{template.name} — #{Time.current.strftime("%b %d, %Y %H:%M")}",
          reference_number: generate_reference_number,
          posted_at: Time.current,
          debits: debit_inputs,
          credits: credit_inputs
        ).tap do |entry|
          entry.total_amount_cents = total_amount_cents
        end
      end

      def debit_inputs
        lines.select { |l| l.debit? }.map { |l| { account: l.account, amount: line_amount_cents(l) } }
      end

      def credit_inputs
        lines.select { |l| l.credit? }.map { |l| { account: l.account, amount: line_amount_cents(l) } }
      end

      def line_amount_cents(line)
        return (line.fixed_amount * 100).round if line.fixed?

        amount_cents || 0
      end

      def amount_cents
        (amount * 100).round if amount
      end

      def total_amount_cents
        amount_cents || 0
      end

      def lines
        @lines ||= template.lines.by_sequence.includes(:account)
      end

      def generate_reference_number
        "ET-#{template.id}-#{Time.current.strftime("%Y%m%d%H%M%S")}-#{SecureRandom.hex(3).upcase}"
      end

      def update_running_balances!(entry)
        posted_date = entry.posted_at.to_date

        entry.accounts.distinct.each do |account|
          balance = Accounting::RunningBalance.find_or_initialize_by(
            account_id: account.id,
            as_of_date: posted_date
          )
          balance.ledger = account.ledger
          balance.balance_cents = account.balance(to_date: posted_date).cents
          balance.save!
        end

        entry.accounts.includes(:ledger).distinct.map(&:ledger).uniq.each do |ledger|
          balance = Accounting::RunningBalance.find_or_initialize_by(
            ledger_id: ledger.id,
            account_id: nil,
            as_of_date: posted_date
          )
          balance.balance_cents = ledger.balance(to_date: posted_date)
          balance.save!
        end
      end
    end
  end
end
