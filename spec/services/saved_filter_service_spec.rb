require "rails_helper"

RSpec.describe SavedFilterService do
  let!(:user) { create(:user) }

  describe "#create!" do
    it "stores filter configuration as JSON" do
      filter = described_class.new(user: user).create!(
        name: "Month End",
        filters: { start_date: "2026-01-01", end_date: "2026-01-31" }
      )

      expect(filter.filters["start_date"]).to eq("2026-01-01")
      expect(filter.filters["end_date"]).to eq("2026-01-31")
    end

    it "associates filter with user" do
      filter = described_class.new(user: user).create!(
        name: "My Filter",
        filters: { start_date: "2026-01-01" }
      )

      expect(filter.user).to eq(user)
    end

    it "sets is_shared when specified" do
      filter = described_class.new(user: user).create!(
        name: "Shared Filter",
        filters: { start_date: "2026-01-01" },
        is_shared: true
      )

      expect(filter.is_shared).to be true
    end

    it "sets as default when specified" do
      filter = described_class.new(user: user).create!(
        name: "Default Filter",
        filters: { start_date: "2026-01-01" },
        set_default: true
      )

      expect(filter.is_default).to be true
    end

    it "removes default from other filters when setting new default" do
      existing = described_class.new(user: user).create!(
        name: "Existing Default",
        filters: { start_date: "2026-01-01" },
        set_default: true
      )

      new_default = described_class.new(user: user).create!(
        name: "New Default",
        filters: { start_date: "2026-02-01" },
        set_default: true
      )

      existing.reload
      expect(existing.is_default).to be false
      expect(new_default.is_default).to be true
    end

    it "rejects invalid filter keys" do
      expect {
        described_class.new(user: user).create!(
          name: "Invalid Filter",
          filters: { invalid_key: "value" }
        )
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#list" do
    let!(:my_filter) { create(:saved_filter, user: user, name: "My Filter") }
    let!(:shared_filter) { create(:saved_filter, user: user, name: "Shared Filter", is_shared: true) }
    let!(:other_user_filter) { create(:saved_filter, name: "Other User Filter") }

    it "returns filters for user including shared" do
      result = described_class.new(user: user).list

      expect(result).to include(my_filter, shared_filter)
      expect(result).not_to include(other_user_filter)
    end

    it "filters by filter_type when specified" do
      create(:saved_filter, user: user, filter_type: "trial_balance")

      result = described_class.new(user: user).list(filter_type: "journal_entry")

      expect(result.all? { |f| f.filter_type == "journal_entry" }).to be true
    end

    it "orders by is_default desc, then name asc" do
      default_filter = create(:saved_filter, user: user, name: "Z Filter", is_default: true)
      normal_filter = create(:saved_filter, user: user, name: "A Filter", is_default: false)

      result = described_class.new(user: user).list

      expect(result.first).to eq(default_filter)
      expect(result.last).to eq(normal_filter)
    end
  end

  describe "#get_default" do
    it "returns default filter for user and type" do
      default = create(:saved_filter, user: user, is_default: true, filter_type: "journal_entry")
      create(:saved_filter, user: user, is_default: false, filter_type: "journal_entry")

      result = described_class.new(user: user).get_default(filter_type: "journal_entry")

      expect(result).to eq(default)
    end

    it "returns nil when no default exists" do
      result = described_class.new(user: user).get_default(filter_type: "journal_entry")

      expect(result).to be_nil
    end
  end

  describe "#apply_saved_filter" do
    it "returns filter parameters as hash" do
      filter = create(:saved_filter,
                      user: user,
                      filters: { start_date: "2026-01-01", branch_id: "5" })

      result = described_class.new(user: user).apply_saved_filter(filter.id)

      expect(result[:start_date]).to eq("2026-01-01")
      expect(result[:branch_id]).to eq("5")
    end

    it "raises error for unauthorized filter" do
      other_user = create(:user)
      filter = create(:saved_filter, user: other_user, is_shared: false)

      expect {
        described_class.new(user: user).apply_saved_filter(filter.id)
      }.to raise_error(ArgumentError, "Not authorized to use this filter")
    end

    it "allows applying shared filter" do
      other_user = create(:user)
      filter = create(:saved_filter, user: other_user, is_shared: true)

      result = described_class.new(user: user).apply_saved_filter(filter.id)

      expect(result).to be_a(Hash)
    end
  end

  describe "#update!" do
    it "updates filter attributes" do
      filter = create(:saved_filter, user: user, name: "Old Name")

      result = described_class.new(user: user).update!(
        filter_id: filter.id,
        name: "New Name"
      )

      expect(result.name).to eq("New Name")
    end

    it "raises error when unauthorized user tries to update" do
      other_user = create(:user)
      filter = create(:saved_filter, user: other_user)

      expect {
        described_class.new(user: user).update!(filter_id: filter.id, name: "New Name")
      }.to raise_error(ArgumentError, "Not authorized to update this filter")
    end

    it "allows manager to update any filter" do
      manager = create(:user, role: :manager)
      other_user = create(:user)
      filter = create(:saved_filter, user: other_user, name: "Old Name")

      result = described_class.new(user: manager).update!(
        filter_id: filter.id,
        name: "New Name"
      )

      expect(result.name).to eq("New Name")
    end
  end

  describe "#destroy!" do
    it "deletes filter" do
      filter = create(:saved_filter, user: user)

      described_class.new(user: user).destroy!(filter_id: filter.id)

      expect(SavedFilter.exists?(filter.id)).to be false
    end

    it "raises error when unauthorized user tries to delete" do
      other_user = create(:user)
      filter = create(:saved_filter, user: other_user)

      expect {
        described_class.new(user: user).destroy!(filter_id: filter.id)
      }.to raise_error(ArgumentError, "Not authorized to delete this filter")
    end

    it "allows manager to delete any filter" do
      manager = create(:user, role: :manager)
      other_user = create(:user)
      filter = create(:saved_filter, user: other_user)

      described_class.new(user: manager).destroy!(filter_id: filter.id)

      expect(SavedFilter.exists?(filter.id)).to be false
    end
  end

  describe "#share_filter!" do
    it "makes filter shared" do
      filter = create(:saved_filter, user: user, is_shared: false)

      described_class.new(user: user).share_filter!(filter.id)

      expect(filter.reload.is_shared).to be true
    end

    it "sets role restriction when provided" do
      filter = create(:saved_filter, user: user)

      described_class.new(user: user).share_filter!(filter.id, role_restriction: "accountant")

      expect(filter.reload.role_restriction).to eq("accountant")
    end
  end

  describe "#unshare_filter!" do
    it "makes filter private" do
      filter = create(:saved_filter, user: user, is_shared: true)

      described_class.new(user: user).unshare_filter!(filter.id)

      expect(filter.reload.is_shared).to be false
      expect(filter.role_restriction).to be_nil
    end
  end
end