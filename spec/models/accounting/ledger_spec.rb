require "rails_helper"

RSpec.describe Accounting::Ledger do
  subject(:ledger) { build(:accounting_ledger) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:account_code) }
    it { is_expected.to validate_presence_of(:account_type) }
    it { is_expected.to validate_uniqueness_of(:account_code) }
  end

  describe "associations" do
    it { is_expected.to have_many(:accounts).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:running_balances).dependent(:restrict_with_error) }
  end

  describe "enums" do
    it "defines account_type enum" do
      expect(ledger).to define_enum_for(:account_type)
        .with_values(asset: "asset", equity: "equity", liability: "liability",
                     revenue: "revenue", expense: "expense")
        .backed_by_column_of_type(:enum)
    end
  end

  describe "scopes" do
    let!(:contra_ledger) { create(:accounting_ledger, contra: true) }
    let!(:non_contra_ledger) { create(:accounting_ledger, contra: false) }

    it "returns contra ledgers" do
      expect(described_class.contra).to contain_exactly(contra_ledger)
    end

    it "returns non-contra ledgers" do
      expect(described_class.non_contra).to contain_exactly(non_contra_ledger)
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:accounting_ledger)).to be_valid
    end
  end
end
