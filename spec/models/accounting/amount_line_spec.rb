require "rails_helper"

RSpec.describe Accounting::AmountLine do
  subject(:amount_line) { build(:accounting_amount_line) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount_type) }
    it { is_expected.to validate_presence_of(:amount_cents) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:entry) }
    it { is_expected.to belong_to(:account) }
  end

  describe "enums" do
    it "defines amount_type enum" do
      expect(amount_line).to define_enum_for(:amount_type)
        .with_values(debit: 0, credit: 1)
        .backed_by_column_of_type(:integer)
    end
  end

  describe "scopes" do
    it "filters by between dates" do
      old = create(:accounting_amount_line, entry: create(:accounting_entry, posted_at: 5.days.ago), amount_type: "debit", amount_cents: 100)
      recent = create(:accounting_amount_line, entry: create(:accounting_entry, posted_at: Time.zone.now), amount_type: "debit", amount_cents: 200)
      result_ids = described_class.between(2.days.ago, Date.current).pluck(:id)
      expect(result_ids).to include(recent.id)
      expect(result_ids).not_to include(old.id)
    end

    it "filters up to a date" do
      old = create(:accounting_amount_line, entry: create(:accounting_entry, posted_at: 5.days.ago), amount_type: "debit", amount_cents: 100)
      recent = create(:accounting_amount_line, entry: create(:accounting_entry, posted_at: Time.zone.now), amount_type: "debit", amount_cents: 200)
      result_ids = described_class.up_to(3.days.ago).pluck(:id)
      expect(result_ids).to include(old.id)
      expect(result_ids).not_to include(recent.id)
    end

    it "filters from a date" do
      old = create(:accounting_amount_line, entry: create(:accounting_entry, posted_at: 5.days.ago), amount_type: "debit", amount_cents: 100)
      recent = create(:accounting_amount_line, entry: create(:accounting_entry, posted_at: Time.zone.now), amount_type: "debit", amount_cents: 200)
      result_ids = described_class.from_date(2.days.ago).pluck(:id)
      expect(result_ids).to include(recent.id)
      expect(result_ids).not_to include(old.id)
    end
  end

  describe ".total" do
    it "sums amount_cents" do
      account = create(:accounting_account)
      entry = build(:accounting_entry, create_lines: false)
      entry.amount_lines.build(account: account, amount_cents: 1000, amount_type: "debit", amount_currency: "PHP")
      entry.amount_lines.build(account: account, amount_cents: 1000, amount_type: "credit", amount_currency: "PHP")
      entry.save!
      expect(described_class.total).to eq(2000)
    end
  end

  describe ".balance" do
    it "returns sum of amount_cents" do
      account = create(:accounting_account)
      entry = build(:accounting_entry, create_lines: false)
      entry.amount_lines.build(account: account, amount_cents: 1000, amount_type: "debit", amount_currency: "PHP")
      entry.amount_lines.build(account: account, amount_cents: 1000, amount_type: "credit", amount_currency: "PHP")
      entry.save!
      expect(described_class.balance).to eq(2000)
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:accounting_amount_line)).to be_valid
    end
  end
end
