require "rails_helper"

RSpec.describe Accounting::Entry do
  subject(:entry) { build(:accounting_entry) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:reference_number) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:posted_at) }
    it { is_expected.to validate_uniqueness_of(:reference_number) }
  end

  describe "associations" do
    it { is_expected.to have_many(:amount_lines).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:accounts).through(:amount_lines) }
  end

  describe "custom validations" do
    it "requires at least one debit amount line" do
      entry = build(:accounting_entry)
      entry.amount_lines.build(account: build(:accounting_account), amount_cents: 100, amount_type: :credit)
      entry.valid?
      expect(entry.errors[:base]).to include("must have at least one debit amount")
    end

    it "requires at least one credit amount line" do
      entry = build(:accounting_entry)
      entry.amount_lines.build(account: build(:accounting_account), amount_cents: 100, amount_type: :debit)
      entry.valid?
      expect(entry.errors[:base]).to include("must have at least one credit amount")
    end

    it "validates debits equal credits" do
      entry = build(:accounting_entry)
      entry.amount_lines.build(account: build(:accounting_account), amount_cents: 100, amount_type: :debit)
      entry.amount_lines.build(account: build(:accounting_account), amount_cents: 50, amount_type: :credit)
      entry.valid?
      expect(entry.errors[:base]).to include("debits (100) do not equal credits (50)")
    end
  end

  describe "scopes" do
    let!(:old_entry) { create(:accounting_entry, posted_at: 5.days.ago) }
    let!(:recent_entry) { create(:accounting_entry, posted_at: Time.zone.now) }

    it "filters by posted_on date" do
      expect(described_class.posted_on(Date.current)).to contain_exactly(recent_entry)
    end

    it "filters up_to date" do
      expect(described_class.up_to(3.days.ago)).to contain_exactly(old_entry)
    end

    it "filters from_date" do
      expect(described_class.from_date(1.day.ago)).to contain_exactly(recent_entry)
    end
  end

  describe ".build" do
    it "builds an entry with debits and credits" do
      account = create(:accounting_account)
      entry = described_class.build(
        description: "Test entry",
        debits: [ { account:, amount: 10000 } ],
        credits: [ { account:, amount: 10000 } ]
      )
      expect(entry).to be_a_new(described_class)
      expect(entry.description).to eq("Test entry")
      expect(entry.amount_lines.size).to eq(2)
    end

    it "generates a reference number when not provided" do
      entry = described_class.build(description: "Test")
      expect(entry.reference_number).to start_with("ENT-")
    end

    it "uses provided posted_at" do
      time = 1.day.ago
      entry = described_class.build(description: "Test", posted_at: time)
      expect(entry.posted_at).to be_within(1.second).of(time)
    end

    it "defaults posted_at to current time" do
      entry = described_class.build(description: "Test")
      expect(entry.posted_at).to be_within(1.second).of(Time.current)
    end
  end

  describe ".generate_reference_number" do
    it "generates a unique reference number" do
      ref = described_class.send(:generate_reference_number)
      expect(ref).to match(/\AENT-\d{8}-\d{6}-[A-F0-9]{8}\z/)
    end
  end

  describe "factory" do
    it "creates a valid record with debits and credits" do
      expect(build(:accounting_entry)).to be_valid
    end
  end
end
