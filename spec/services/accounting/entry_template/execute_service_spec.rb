require "rails_helper"

RSpec.describe Accounting::EntryTemplate::ExecuteService do
  describe "#execute" do
    let(:debit_account) { create(:accounting_account, name: "Cash at Bank") }
    let(:credit_account) { create(:accounting_account, name: "Interest Income") }
    let(:template) do
      create(:accounting_entry_template).tap do |t|
        t.lines.destroy_all
        t.lines << create(:accounting_entry_template_line,
          entry_template: t, account: debit_account, direction: "debit",
          amount_mode: "variable", sequence_index: 1)
        t.lines << create(:accounting_entry_template_line,
          entry_template: t, account: credit_account, direction: "credit",
          amount_mode: "variable", sequence_index: 2)
      end
    end

    describe "preview (no amount)" do
      it "returns preview lines without persisting" do
        result = described_class.run(template: template)

        expect(result).to be_valid
        preview = result.result
        expect(preview).to be_an(Array)
        expect(preview.size).to eq(2)
      end
    end

    describe "posting (with amount)" do
      it "creates a journal entry" do
        expect {
          described_class.run!(template: template, amount: 10_000, posting: true)
        }.to change(Accounting::Entry, :count).by(1)
      end

      it "creates the entry with correct amounts" do
        entry = described_class.run!(template: template, amount: 10_000, posting: true)

        expect(entry.amount_lines.size).to eq(2)
        debit_line = entry.amount_lines.find_by(amount_type: "debit")
        credit_line = entry.amount_lines.find_by(amount_type: "credit")

        expect(debit_line.amount_cents).to eq(1_000_000)
        expect(credit_line.amount_cents).to eq(1_000_000)
      end

      it "associates the template with the entry" do
        entry = described_class.run!(template: template, amount: 10_000, posting: true)

        expect(template.reload.entry).to eq(entry)
      end

      it "stores total_amount_cents" do
        entry = described_class.run!(template: template, amount: 5_000, posting: true)

        expect(entry.amount_lines.sum(:amount_cents)).to eq(1_000_000)
      end

      it "rejects zero amount" do
        expect {
          described_class.run!(template: template, amount: 0, posting: true)
        }.to raise_error(ActiveInteraction::InvalidInteractionError)
      end

      it "rejects negative amount" do
        expect {
          described_class.run!(template: template, amount: -100, posting: true)
        }.to raise_error(ActiveInteraction::InvalidInteractionError)
      end

      context "with fixed and variable lines" do
        let(:mixed_template) do
          create(:accounting_entry_template, name: "Mixed Entry").tap do |t|
            t.lines.destroy_all
            t.lines << create(:accounting_entry_template_line,
              entry_template: t, account: debit_account, direction: "debit",
              amount_mode: "fixed", fixed_amount: 500, sequence_index: 1)
            t.lines << create(:accounting_entry_template_line,
              entry_template: t, account: debit_account, direction: "debit",
              amount_mode: "variable", sequence_index: 2)
            t.lines << create(:accounting_entry_template_line,
              entry_template: t, account: credit_account, direction: "credit",
              amount_mode: "fixed", fixed_amount: 500, sequence_index: 3)
            t.lines << create(:accounting_entry_template_line,
              entry_template: t, account: credit_account, direction: "credit",
              amount_mode: "variable", sequence_index: 4)
          end
        end

        it "applies fixed amounts and variable amounts" do
          entry = described_class.run!(template: mixed_template, amount: 10_000, posting: true)

          expect(entry.amount_lines.size).to eq(4)
          debits = entry.amount_lines.where(amount_type: "debit").order(:id)
          credits = entry.amount_lines.where(amount_type: "credit").order(:id)
          debit_fixed = debits.first
          debit_variable = debits.last
          credit_fixed = credits.first
          credit_variable = credits.last

          expect(debit_fixed.amount_cents).to eq(50_000)
          expect(debit_variable.amount_cents).to eq(1_000_000)
          expect(credit_fixed.amount_cents).to eq(50_000)
          expect(credit_variable.amount_cents).to eq(1_000_000)
        end
      end
    end

    describe "validation" do
      it "rejects invalid templates" do
        invalid_template = build(:accounting_entry_template)
        invalid_template.lines = [ build(:accounting_entry_template_line, entry_template: invalid_template, direction: "debit") ]
        result = described_class.run(template: invalid_template)

        expect(result).not_to be_valid
      end
    end
  end
end
