require "rails_helper"

RSpec.describe Accounting::JournalEntryQueryService do
  let!(:account) { create(:accounting_account) }

  describe "#call" do
    it "filters by date range" do
      entry1 = create(:accounting_entry, posted_at: 5.days.ago)
      entry2 = create(:accounting_entry, posted_at: 2.days.ago)

      result = described_class.new(
        start_date: 3.days.ago.to_date,
        end_date: Date.current
      ).call

      expect(result).to include(entry2)
      expect(result).not_to include(entry1)
    end

    it "filters by entry type" do
      system_entry = create(:accounting_entry, entry_type: "system_entry")
      manual_entry = create(:accounting_entry, entry_type: "manual_entry")

      result = described_class.new(entry_type: "manual_entry").call

      expect(result).to include(manual_entry)
      expect(result).not_to include(system_entry)
    end

    it "filters by status" do
      posted_entry = create(:accounting_entry, status: "posted")
      pending_entry = create(:accounting_entry, status: "pending")

      result = described_class.new(status: "posted").call

      expect(result).to include(posted_entry)
      expect(result).not_to include(pending_entry)
    end

    it "filters by source_module" do
      loans_entry = create(:accounting_entry, source_module: "source_loans")
      manual_entry = create(:accounting_entry, source_module: "source_manual")

      result = described_class.new(source_module: "source_loans").call

      expect(result).to include(loans_entry)
      expect(result).not_to include(manual_entry)
    end

    it "filters by reference number (partial match)" do
      entry = create(:accounting_entry, reference_number: "JV-2026-001")

      result = described_class.new(reference_number: "JV-2026").call

      expect(result).to include(entry)
    end

    it "filters by created_by_id" do
      user1 = create(:user)
      user2 = create(:user)

      entry1 = create(:accounting_entry, created_by: user1)
      entry2 = create(:accounting_entry, created_by: user2)

      result = described_class.new(created_by_id: user1.id).call

      expect(result).to include(entry1)
      expect(result).not_to include(entry2)
    end

    it "filters by has_attachments" do
      entry_with_attachment = create(:accounting_entry, has_attachments: true)
      entry_without_attachment = create(:accounting_entry, has_attachments: false)

      result = described_class.new(has_attachments: true).call

      expect(result).to include(entry_with_attachment)
      expect(result).not_to include(entry_without_attachment)
    end

    it "filters by inter_branch" do
      inter_branch_entry = create(:accounting_entry, inter_branch: true)
      normal_entry = create(:accounting_entry, inter_branch: false)

      result = described_class.new(inter_branch: true).call

      expect(result).to include(inter_branch_entry)
      expect(result).not_to include(normal_entry)
    end

    it "combines multiple filters" do
      entry1 = create(:accounting_entry, entry_type: "manual_entry", status: "posted")
      entry2 = create(:accounting_entry, entry_type: "system_entry", status: "posted")
      entry3 = create(:accounting_entry, entry_type: "manual_entry", status: "pending")

      result = described_class.new(
        entry_type: "manual_entry",
        status: "posted"
      ).call

      expect(result).to include(entry1)
      expect(result).not_to include(entry2)
      expect(result).not_to include(entry3)
    end

    it "returns entries ordered by posted_at desc" do
      old_entry = create(:accounting_entry, posted_at: 10.days.ago)
      recent_entry = create(:accounting_entry, posted_at: 1.day.ago)

      result = described_class.new.call

      expect(result.first).to eq(recent_entry)
      expect(result.last).to eq(old_entry)
    end

    it "handles empty filters gracefully" do
      entry = create(:accounting_entry)

      result = described_class.new.call

      expect(result).to include(entry)
    end
  end
end