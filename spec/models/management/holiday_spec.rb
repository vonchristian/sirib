require "rails_helper"

RSpec.describe Management::Holiday do
  let(:cooperative) { create(:cooperative) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "scopes" do
    let!(:holiday) { create(:management_holiday, date: Date.new(2026, 12, 25), name: "Christmas", recurring: true, cooperative: cooperative) }
    let!(:one_off) { create(:management_holiday, date: Date.new(2026, 7, 8), name: "Special Non-Working", recurring: false, cooperative: cooperative) }

    it "on_date finds exact matches" do
      expect(described_class.on_date(Date.new(2026, 12, 25))).to include(holiday)
    end

    it "recurring scope returns only recurring holidays" do
      expect(described_class.recurring).to include(holiday)
      expect(described_class.recurring).not_to include(one_off)
    end

    it "between scope returns holidays in date range" do
      expect(described_class.between(Date.new(2026, 12, 1), Date.new(2026, 12, 31))).to include(holiday)
    end
  end

  describe ".holiday?" do
    let!(:xmas) { create(:management_holiday, date: Date.new(2026, 12, 25), name: "Christmas", recurring: true, cooperative: cooperative) }
    let!(:one_off) { create(:management_holiday, date: Date.new(2026, 7, 8), name: "Special Non-Working", recurring: false, cooperative: cooperative) }

    it "returns true for exact date match" do
      expect(described_class.holiday?(Date.new(2026, 7, 8), cooperative: cooperative)).to be true
    end

    it "returns true for recurring holiday matching month and day" do
      expect(described_class.holiday?(Date.new(2027, 12, 25), cooperative: cooperative)).to be true
    end

    it "returns false for non-holiday date" do
      expect(described_class.holiday?(Date.new(2026, 7, 9), cooperative: cooperative)).to be false
    end
  end
end
