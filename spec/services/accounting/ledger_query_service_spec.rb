require "rails_helper"

RSpec.describe Accounting::LedgerQueryService do
  let(:cooperative) { create(:cooperative) }
  let(:ledger) { create(:accounting_ledger, cooperative: cooperative) }
  let(:account) { create(:accounting_account, ledger: ledger, cooperative: cooperative, account_type: "asset") }
  let(:user) { create(:user, cooperative: cooperative) }
  let(:service) { described_class.new(account: account, filters: filters, sort_order: sort_order) }

  let(:filters) { {} }
  let(:sort_order) { "desc" }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  def update_line!(line, attrs)
    AppendOnlyOverride.with_override(reason: "test setup") { line.update!(attrs) }
  end

  describe "#scope" do
    it "returns filtered amount lines for the account" do
      entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now)
      line = entry.amount_lines.first
      update_line!(line, account: account, cooperative: cooperative)

      result = service.scope
      expect(result).to include(line)
    end

    it "does not include amount lines for other accounts" do
      other_account = create(:accounting_account, ledger: ledger, cooperative: cooperative)
      entry = create(:accounting_entry, cooperative: cooperative)
      line = entry.amount_lines.first
      update_line!(line, account: other_account, cooperative: cooperative)

      result = service.scope
      expect(result).to be_empty
    end

    context "with date filters" do
      let(:filters) { { from_date: Date.new(2024, 1, 1), to_date: Date.new(2024, 12, 31) } }

      it "filters by date range" do
        entry_in_range = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.local(2024, 6, 15))
        line_in_range = entry_in_range.amount_lines.first
        update_line!(line_in_range, account: account, cooperative: cooperative)

        entry_outside = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.local(2023, 6, 15))
        line_outside = entry_outside.amount_lines.first
        update_line!(line_outside, account: account, cooperative: cooperative)

        result = service.scope
        expect(result).to include(line_in_range)
        expect(result).not_to include(line_outside)
      end
    end

    context "with amount filters" do
      let(:filters) { { amount_min: "50", amount_max: "150" } }

      it "filters by amount range" do
        entry = create(:accounting_entry, cooperative: cooperative)
        matching_line = entry.amount_lines.first
        update_line!(matching_line, account: account, cooperative: cooperative, amount_cents: 10_000)

        other_entry = create(:accounting_entry, cooperative: cooperative)
        other_line = other_entry.amount_lines.first
        update_line!(other_line, account: account, cooperative: cooperative, amount_cents: 100)

        result = service.scope
        expect(result).to include(matching_line)
        expect(result).not_to include(other_line)
      end
    end

    context "with debit_only filter" do
      let(:filters) { { debit_only: "1" } }

      it "filters to only debit lines" do
        entry = create(:accounting_entry, cooperative: cooperative)
        debit_line = entry.amount_lines.where(amount_type: :debit).first
        update_line!(debit_line, account: account, cooperative: cooperative) if debit_line

        credit_line = entry.amount_lines.where(amount_type: :credit).first
        update_line!(credit_line, account: account, cooperative: cooperative) if credit_line

        result = service.scope
        expect(result).to include(debit_line) if debit_line
        expect(result).not_to include(credit_line) if credit_line
      end
    end

    context "with reference_number filter" do
      let(:filters) { { reference_number: "ENT-123" } }

      it "filters by reference number" do
        matching_entry = create(:accounting_entry, cooperative: cooperative, reference_number: "ENT-123-TEST")
        matching_line = matching_entry.amount_lines.first
        update_line!(matching_line, account: account, cooperative: cooperative)

        non_matching_entry = create(:accounting_entry, cooperative: cooperative, reference_number: "ENT-999-OTHER")
        non_matching_line = non_matching_entry.amount_lines.first
        update_line!(non_matching_line, account: account, cooperative: cooperative)

        result = service.scope
        expect(result).to include(matching_line)
        expect(result).not_to include(non_matching_line)
      end
    end

    context "with entry_type filter" do
      let(:filters) { { entry_type: "interest_entry" } }

      it "filters by entry type" do
        matching_entry = create(:accounting_entry, cooperative: cooperative, entry_type: "interest_entry")
        matching_line = matching_entry.amount_lines.first
        update_line!(matching_line, account: account, cooperative: cooperative)

        non_matching_entry = create(:accounting_entry, cooperative: cooperative, entry_type: "manual_entry")
        non_matching_line = non_matching_entry.amount_lines.first
        update_line!(non_matching_line, account: account, cooperative: cooperative)

        result = service.scope
        expect(result).to include(matching_line)
        expect(result).not_to include(non_matching_line)
      end
    end
  end

  describe "#build_ledger_lines" do
    it "returns ledger line structs" do
      entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now)
      line = entry.amount_lines.first
      update_line!(line, account: account, cooperative: cooperative)

      ledger_lines = service.build_ledger_lines([ line ])
      expect(ledger_lines).to be_an(Array)
      expect(ledger_lines.first).to be_an(Accounting::LedgerLine)
      expect(ledger_lines.first.journal_entry_id).to eq(entry.id)
      expect(ledger_lines.first.entry_number).to eq(entry.reference_number)
      expect(ledger_lines.first.memo).to eq(entry.description)
    end

    it "computes running balance correctly for asset accounts" do
      asc_service = described_class.new(account: account, filters: {}, sort_order: "asc")

      posted_at = Time.zone.local(2024, 1, 1)
      entry1 = create(:accounting_entry, cooperative: cooperative, posted_at: posted_at)
      line1 = entry1.amount_lines.where(amount_type: :debit).first
      update_line!(line1, account: account, cooperative: cooperative, amount_cents: 10_000)

      entry2 = create(:accounting_entry, cooperative: cooperative, posted_at: posted_at + 1.day)
      line2 = entry2.amount_lines.where(amount_type: :credit).first
      update_line!(line2, account: account, cooperative: cooperative, amount_cents: 3_000)

      entry3 = create(:accounting_entry, cooperative: cooperative, posted_at: posted_at + 2.days)
      line3 = entry3.amount_lines.where(amount_type: :debit).first
      update_line!(line3, account: account, cooperative: cooperative, amount_cents: 5_000)

      lines = [ line1, line2, line3 ]
      ledger_lines = asc_service.build_ledger_lines(lines)

      expect(ledger_lines[0].running_balance.cents).to eq(10_000)
      expect(ledger_lines[1].running_balance.cents).to eq(7_000)
      expect(ledger_lines[2].running_balance.cents).to eq(12_000)
    end

    it "computes running balance correctly for liability accounts" do
      liability_account = create(:accounting_account, ledger: ledger, cooperative: cooperative, account_type: "liability")
      liability_service = described_class.new(account: liability_account, filters: {}, sort_order: "asc")

      posted_at = Time.zone.local(2024, 1, 1)
      entry1 = create(:accounting_entry, cooperative: cooperative, posted_at: posted_at)
      line1 = entry1.amount_lines.where(amount_type: :credit).first
      update_line!(line1, account: liability_account, cooperative: cooperative, amount_cents: 10_000)

      entry2 = create(:accounting_entry, cooperative: cooperative, posted_at: posted_at + 1.day)
      line2 = entry2.amount_lines.where(amount_type: :debit).first
      update_line!(line2, account: liability_account, cooperative: cooperative, amount_cents: 3_000)

      lines = [ line1, line2 ]
      ledger_lines = liability_service.build_ledger_lines(lines)

      expect(ledger_lines[0].running_balance.cents).to eq(10_000)
      expect(ledger_lines[1].running_balance.cents).to eq(7_000)
    end

    it "includes posted_by from entry creator" do
      entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now, created_by: user)
      line = entry.amount_lines.first
      update_line!(line, account: account, cooperative: cooperative)

      ledger_lines = service.build_ledger_lines([ line ])
      expect(ledger_lines.first.posted_by).to eq(user.email_address.split("@").first)
    end

    it "handles empty input" do
      ledger_lines = service.build_ledger_lines([])
      expect(ledger_lines).to be_empty
    end
  end

  describe "#summary" do
    it "returns summary hash with correct keys" do
      result = service.summary
      expect(result).to have_key(:opening)
      expect(result).to have_key(:total_debits)
      expect(result).to have_key(:total_credits)
      expect(result).to have_key(:net_movement)
      expect(result).to have_key(:current_balance)
    end

    it "computes totals correctly" do
      AppendOnlyOverride.with_override(reason: "test setup") do
        entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now)
        debit_line = entry.amount_lines.where(amount_type: :debit).first
        debit_line.update!(account: account, cooperative: cooperative, amount_cents: 15_000)

        credit_line = entry.amount_lines.where(amount_type: :credit).first
        credit_line.update!(account: account, cooperative: cooperative, amount_cents: 15_000)
      end

      result = service.summary
      expect(result[:total_debits].cents).to eq(15_000)
      expect(result[:total_credits].cents).to eq(15_000)
    end

    it "returns zero totals for account with no transactions" do
      result = service.summary
      expect(result[:total_debits].cents).to eq(0)
      expect(result[:total_credits].cents).to eq(0)
    end
  end
end
