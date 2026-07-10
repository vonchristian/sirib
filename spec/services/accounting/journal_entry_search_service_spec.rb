require "rails_helper"

RSpec.describe Accounting::JournalEntrySearchService do
  describe "#call" do
    it "finds entry by reference number" do
      entry = create(:accounting_entry, reference_number: "JV-2026-001")

      result = described_class.new(query: "JV-2026").call

      expect(result).to include(entry)
    end

    it "finds entry by description text" do
      entry = create(:accounting_entry, description: "Loan disbursement for member")

      result = described_class.new(query: "disbursement").call

      expect(result).to include(entry)
    end

    it "finds entries by partial reference match" do
      entry1 = create(:accounting_entry, reference_number: "JV-2026-001")
      entry2 = create(:accounting_entry, reference_number: "JV-2026-002")

      result = described_class.new(query: "JV-2026").call

      expect(result).to include(entry1)
      expect(result).to include(entry2)
    end

    it "returns empty collection for blank query" do
      create(:accounting_entry)

      result = described_class.new(query: "").call

      expect(result).to be_empty
    end

    it "returns empty collection for nil query" do
      create(:accounting_entry)

      result = described_class.new(query: nil).call

      expect(result).to be_empty
    end

    it "orders results by posted_at desc" do
      old_entry = create(:accounting_entry, posted_at: 10.days.ago, reference_number: "OLD-ENTRY")
      recent_entry = create(:accounting_entry, posted_at: 1.day.ago, reference_number: "RECENT-ENTRY")

      result = described_class.new(query: "ENTRY").call

      expect(result.first).to eq(recent_entry)
      expect(result.last).to eq(old_entry)
    end

    it "filters by account_id when provided" do
      account1 = create(:accounting_account)
      account2 = create(:accounting_account)

      entry1 = nil
      entry2 = nil

      AppendOnlyOverride.with_override(reason: "test setup") do
        entry1 = create(:accounting_entry)
        entry1.amount_lines.first.update!(account: account1)
        entry2 = create(:accounting_entry)
        entry2.amount_lines.first.update!(account: account2)
      end

      result = described_class.new(query: entry1.reference_number, account_id: account1.id).call

      expect(result).to include(entry1)
      expect(result).not_to include(entry2)
    end
  end
end
