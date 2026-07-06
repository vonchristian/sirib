require "rails_helper"

RSpec.describe Accounting::PostingEngine do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  let(:debit_account) { create(:accounting_account, cooperative: cooperative) }
  let(:credit_account) { create(:accounting_account, cooperative: cooperative) }

  let(:template) do
    Accounting::EntryTemplate.create!(name: "Test Template", cooperative: cooperative).tap do |t|
      t.lines.create!(account: debit_account, direction: "debit", amount_mode: "variable", sequence_index: 1)
      t.lines.create!(account: credit_account, direction: "credit", amount_mode: "variable", sequence_index: 2)
    end
  end

  describe "#preview" do
    it "returns preview lines without persisting" do
      engine = described_class.new(template: template, input: { amount: 1000 })
      lines = engine.preview

      expect(lines).to be_an(Array)
      expect(lines.size).to eq(2)
      expect(lines[0][:account]).to eq(debit_account)
      expect(lines[1][:account]).to eq(credit_account)
    end

    it "resolves amounts in cents" do
      engine = described_class.new(template: template, input: { amount: 500 })
      lines = engine.preview

      expect(lines[0][:amount_cents]).to eq(50_000)
      expect(lines[1][:amount_cents]).to eq(50_000)
    end
  end

  describe "#post!" do
    it "creates a journal entry" do
      engine = described_class.new(template: template, input: { amount: 10_000 })

      expect { engine.post! }.to change(Accounting::Entry, :count).by(1)
    end

    it "creates entry with correct amount lines" do
      engine = described_class.new(template: template, input: { amount: 10_000 })
      entry = engine.post!

      expect(entry.amount_lines.size).to eq(2)
      expect(entry.amount_lines.debit.first.amount_cents).to eq(1_000_000)
      expect(entry.amount_lines.credit.first.amount_cents).to eq(1_000_000)
    end

    it "sets total_amount_cents" do
      engine = described_class.new(template: template, input: { amount: 5_000 })
      entry = engine.post!

      expect(entry.amount_lines.sum(:amount_cents)).to eq(1_000_000)
    end

    context "with mixed fixed and variable lines" do
      let(:mixed_template) do
        Accounting::EntryTemplate.create!(name: "Mixed Entry", cooperative: cooperative).tap do |t|
          t.lines.create!(account: debit_account, direction: "debit", amount_mode: "fixed", fixed_amount: 500, sequence_index: 1)
          t.lines.create!(account: debit_account, direction: "debit", amount_mode: "variable", sequence_index: 2)
          t.lines.create!(account: credit_account, direction: "credit", amount_mode: "fixed", fixed_amount: 500, sequence_index: 3)
          t.lines.create!(account: credit_account, direction: "credit", amount_mode: "variable", sequence_index: 4)
        end
      end

      it "applies fixed and variable amounts correctly" do
        engine = described_class.new(template: mixed_template, input: { amount: 10_000 })
        entry = engine.post!

        expect(entry.amount_lines.size).to eq(4)
        debits = entry.amount_lines.debit.order(:id)
        credits = entry.amount_lines.credit.order(:id)

        expect(debits[0].amount_cents).to eq(50_000)
        expect(debits[1].amount_cents).to eq(1_000_000)
        expect(credits[0].amount_cents).to eq(50_000)
        expect(credits[1].amount_cents).to eq(1_000_000)
      end
    end
  end
end
