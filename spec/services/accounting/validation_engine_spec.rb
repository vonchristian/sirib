require "rails_helper"

RSpec.describe Accounting::ValidationEngine do
  describe ".validate!" do
    let(:account) { create(:accounting_account) }

    it "passes for a valid balanced entry" do
      entry = build(:accounting_entry)
      expect(described_class.validate!(entry)).to be true
    end

    it "raises for an entry with no lines" do
      entry = build(:accounting_entry)
      entry.amount_lines = []
      expect { described_class.validate!(entry) }
        .to raise_error(described_class::ValidationError, /at least one line/)
    end

    it "raises for an entry with no debit lines" do
      entry = build(:accounting_entry)
      entry.amount_lines = [
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "credit", amount_cents: 100)
      ]
      expect { described_class.validate!(entry) }
        .to raise_error(described_class::ValidationError, /at least one debit/)
    end

    it "raises for an entry with no credit lines" do
      entry = build(:accounting_entry)
      entry.amount_lines = [
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "debit", amount_cents: 100)
      ]
      expect { described_class.validate!(entry) }
        .to raise_error(described_class::ValidationError, /at least one credit/)
    end

    it "raises for unbalanced entry" do
      entry = build(:accounting_entry)
      entry.amount_lines = [
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "debit", amount_cents: 200),
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "credit", amount_cents: 100)
      ]
      expect { described_class.validate!(entry) }
        .to raise_error(described_class::ValidationError, /unbalanced/)
    end

    it "raises for line with zero amount" do
      entry = build(:accounting_entry)
      entry.amount_lines = [
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "debit", amount_cents: 0),
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "credit", amount_cents: 0)
      ]
      expect { described_class.validate!(entry) }
        .to raise_error(described_class::ValidationError, /amount must be positive/)
    end

    it "raises for line without account" do
      entry = build(:accounting_entry)
      entry.amount_lines = [
        build(:accounting_amount_line, entry: entry, account: nil, amount_type: "debit", amount_cents: 100),
        build(:accounting_amount_line, entry: entry, account: account, amount_type: "credit", amount_cents: 100)
      ]
      expect { described_class.validate!(entry) }
        .to raise_error(described_class::ValidationError, /must have an account/)
    end
  end

  describe ".balanced?" do
    it "returns true for balanced entry" do
      entry = build(:accounting_entry)
      expect(described_class.balanced?(entry)).to be true
    end

    it "returns false for unbalanced entry" do
      entry = build(:accounting_entry)
      entry.amount_lines.first.amount_cents = 500
      expect(described_class.balanced?(entry)).to be false
    end
  end
end
