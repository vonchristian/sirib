require "rails_helper"

RSpec.describe Accounting::Account do
  subject(:account) { build(:accounting_account) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:account_code) }
    it { is_expected.to validate_presence_of(:account_type) }
    it { is_expected.to validate_uniqueness_of(:account_code) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:ledger) }
    it { is_expected.to have_many(:amount_lines).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:running_balances).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:cash_accounts).dependent(:destroy) }
  end

  describe "enums" do
    it "defines account_type enum" do
      expect(account).to define_enum_for(:account_type)
        .with_values(asset: "asset", equity: "equity", liability: "liability",
                     revenue: "revenue", expense: "expense")
        .backed_by_column_of_type(:enum)
    end

    it "defines status enum" do
      expect(account).to define_enum_for(:status)
        .with_values(active: "active", inactive: "inactive")
        .backed_by_column_of_type(:string)
    end
  end

  describe "default attributes" do
    it "defaults status to active" do
      expect(build(:accounting_account).status).to eq("active")
    end

    it "defaults postable to true" do
      expect(build(:accounting_account).postable).to be true
    end
  end

  describe "#active?" do
    it "returns true when status is active" do
      account = build(:accounting_account, status: :active)
      expect(account.active?).to be true
    end

    it "returns false when status is inactive" do
      account = build(:accounting_account, status: :inactive)
      expect(account.active?).to be false
    end
  end

  describe "#postable?" do
    it "returns true when postable is true" do
      account = build(:accounting_account, postable: true)
      expect(account.postable?).to be true
    end

    it "returns false when postable is false" do
      account = build(:accounting_account, postable: false)
      expect(account.postable?).to be false
    end
  end

  describe "scopes" do
    let!(:contra_account) { create(:accounting_account, contra: true) }
    let!(:non_contra_account) { create(:accounting_account, contra: false) }

    it "returns contra accounts" do
      expect(described_class.contra).to contain_exactly(contra_account)
    end

    it "returns non-contra accounts" do
      expect(described_class.non_contra).to contain_exactly(non_contra_account)
    end
  end

  describe "postable scopes" do
    let!(:postable_account) { create(:accounting_account, postable: true) }
    let!(:non_postable_account) { create(:accounting_account, postable: false) }

    it "returns postable accounts" do
      expect(described_class.postable).to contain_exactly(postable_account)
    end

    it "returns non-postable accounts" do
      expect(described_class.non_postable).to contain_exactly(non_postable_account)
    end
  end

  describe "#normal_credit_balance?" do
    it "returns false for asset" do
      account = build(:accounting_account, account_type: :asset)
      expect(account.normal_credit_balance?).to be false
    end

    it "returns false for expense" do
      account = build(:accounting_account, account_type: :expense)
      expect(account.normal_credit_balance?).to be false
    end

    it "returns true for liability" do
      account = build(:accounting_account, account_type: :liability)
      expect(account.normal_credit_balance?).to be true
    end

    it "returns true for equity" do
      account = build(:accounting_account, account_type: :equity)
      expect(account.normal_credit_balance?).to be true
    end

    it "returns true for revenue" do
      account = build(:accounting_account, account_type: :revenue)
      expect(account.normal_credit_balance?).to be true
    end
  end

  describe "#balance" do
    let(:entry) { create(:accounting_entry, posted_at: Time.current) }

    context "for a debit-normal account (asset)" do
      let(:account) { create(:accounting_account, account_type: :asset) }

      it "calculates balance as debits minus credits" do
        create(:accounting_amount_line, entry:, account:, amount_type: "debit", amount_cents: 10000)
        create(:accounting_amount_line, entry:, account:, amount_type: "credit", amount_cents: 3000)
        expect(account.balance).to eq(Money.new(7000, "PHP"))
      end

      it "returns Money object" do
        expect(account.balance).to be_a(Money)
      end

      it "filters by date range" do
        old_entry = create(:accounting_entry, posted_at: 5.days.ago)
        create(:accounting_amount_line, entry: old_entry, account:, amount_type: "debit", amount_cents: 10000)
        expect(account.balance(from_date: 3.days.ago)).to eq(Money.new(0, "PHP"))
      end
    end

    context "for a contra asset account" do
      let(:account) { create(:accounting_account, account_type: :asset, contra: true) }

      it "reverses the normal balance calculation" do
        create(:accounting_amount_line, entry:, account:, amount_type: "debit", amount_cents: 5000)
        create(:accounting_amount_line, entry:, account:, amount_type: "credit", amount_cents: 2000)
        expect(account.balance).to eq(Money.new(-3000, "PHP"))
      end
    end

    context "for a credit-normal account (liability)" do
      let(:account) { create(:accounting_account, account_type: :liability) }

      it "calculates balance as credits minus debits" do
        create(:accounting_amount_line, entry:, account:, amount_type: "debit", amount_cents: 2000)
        create(:accounting_amount_line, entry:, account:, amount_type: "credit", amount_cents: 10000)
        expect(account.balance).to eq(Money.new(8000, "PHP"))
      end
    end
  end

  describe ".balance" do
    it "sums balances of all accounts" do
      entry = create(:accounting_entry, posted_at: Time.current)
      a1 = create(:accounting_account, account_type: :asset)
      a2 = create(:accounting_account, account_type: :asset)
      create(:accounting_amount_line, entry:, account: a1, amount_type: "debit", amount_cents: 5000)
      create(:accounting_amount_line, entry:, account: a2, amount_type: "debit", amount_cents: 3000)
      expect(described_class.balance).to eq(Money.new(8000, "PHP"))
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:accounting_account)).to be_valid
    end
  end
end