require "rails_helper"

RSpec.describe Accounting::EntryTemplate::ValidateService do
  describe "#execute" do
    let(:debit_account) { create(:accounting_account, name: "Cash") }
    let(:credit_account) { create(:accounting_account, name: "Revenue") }

    context "with valid template" do
      it "returns the template" do
        template = create(:accounting_entry_template)
        result = described_class.run(template: template)

        expect(result).to be_valid
        expect(result.result).to eq(template)
      end
    end

    context "with only one line" do
      it "adds error" do
        template = build(:accounting_entry_template)
        template.lines = [ build(:accounting_entry_template_line, entry_template: template, direction: "debit") ]
        result = described_class.run(template: template)

        expect(result).not_to be_valid
        expect(result.errors.full_messages).to include(/must have at least 2 lines/i)
      end
    end

    context "without both sides" do
      it "adds error when missing credit" do
        template = build(:accounting_entry_template)
        template.lines = [
          build(:accounting_entry_template_line, entry_template: template, direction: "debit", sequence_index: 1),
          build(:accounting_entry_template_line, entry_template: template, direction: "debit", sequence_index: 2)
        ]
        result = described_class.run(template: template)

        expect(result).not_to be_valid
        expect(result.errors.full_messages).to include(/must have at least one debit and one credit/i)
      end
    end

    context "with unbalanced fixed amounts" do
      it "adds error" do
        template = build(:accounting_entry_template)
        template.lines = [
          build(:accounting_entry_template_line, entry_template: template, account: debit_account, direction: "debit", amount_mode: "fixed", fixed_amount: 100, sequence_index: 1),
          build(:accounting_entry_template_line, entry_template: template, account: credit_account, direction: "credit", amount_mode: "variable", sequence_index: 2)
        ]
        result = described_class.run(template: template)

        expect(result).not_to be_valid
        expect(result.errors.full_messages).to include(/fixed amount debits.*must equal/i)
      end
    end

    context "with multiple variable lines on one side" do
      it "adds error" do
        template = build(:accounting_entry_template)
        template.lines = [
          build(:accounting_entry_template_line, entry_template: template, account: debit_account, direction: "debit", amount_mode: "variable", sequence_index: 1),
          build(:accounting_entry_template_line, entry_template: template, account: debit_account, direction: "debit", amount_mode: "variable", sequence_index: 2),
          build(:accounting_entry_template_line, entry_template: template, account: credit_account, direction: "credit", amount_mode: "variable", sequence_index: 3)
        ]
        result = described_class.run(template: template)

        expect(result).not_to be_valid
        expect(result.errors.full_messages).to include(/at most one variable/i)
      end
    end

    context "with fixed line missing amount" do
      it "adds error" do
        template = build(:accounting_entry_template)
        template.lines = [
          build(:accounting_entry_template_line, entry_template: template, account: debit_account, direction: "debit", amount_mode: "variable", sequence_index: 1),
          build(:accounting_entry_template_line, entry_template: template, account: credit_account, direction: "credit", amount_mode: "fixed", fixed_amount: nil, sequence_index: 2)
        ]
        result = described_class.run(template: template)

        expect(result).not_to be_valid
        expect(result.errors.full_messages).to include(/must have a positive amount/i)
      end
    end
  end
end
