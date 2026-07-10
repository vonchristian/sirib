require "rails_helper"

RSpec.describe Accounting::TemplateResolver do
  describe "#resolve_lines" do
    let(:debit_account) { create(:accounting_account) }
    let(:credit_account) { create(:accounting_account) }

    let(:template) do
      t = build(:accounting_entry_template)
      t.lines = [
        build(:accounting_entry_template_line,
          entry_template: t, account: debit_account, direction: "debit",
          amount_mode: "variable", sequence_index: 1),
        build(:accounting_entry_template_line,
          entry_template: t, account: credit_account, direction: "credit",
          amount_mode: "variable", sequence_index: 2)
      ]
      t.save!
      t
    end

    it "returns resolved lines with correct accounts" do
      resolver = described_class.new(template, { amount: 1000 })
      lines = resolver.resolve_lines

      expect(lines.size).to eq(2)
      expect(lines[0][:account]).to eq(debit_account)
      expect(lines[0][:direction]).to eq("debit")
      expect(lines[1][:account]).to eq(credit_account)
      expect(lines[1][:direction]).to eq("credit")
    end

    it "resolves variable amounts to cents" do
      resolver = described_class.new(template, { amount: 1000 })
      lines = resolver.resolve_lines

      expect(lines[0][:amount_cents]).to eq(100_000)
      expect(lines[1][:amount_cents]).to eq(100_000)
    end

    it "resolves fixed amounts" do
      template.lines.destroy_all
      template.lines = [
        build(:accounting_entry_template_line,
          entry_template: template, account: debit_account, direction: "debit",
          amount_mode: "fixed", fixed_amount: 500, sequence_index: 1),
        build(:accounting_entry_template_line,
          entry_template: template, account: credit_account, direction: "credit",
          amount_mode: "fixed", fixed_amount: 500, sequence_index: 2)
      ]
      template.save!

      resolver = described_class.new(template, { amount: 1000 })
      lines = resolver.resolve_lines

      expect(lines[0][:amount_cents]).to eq(50_000)
      expect(lines[1][:amount_cents]).to eq(50_000)
    end

    it "defaults to zero for variable lines without input" do
      resolver = described_class.new(template, {})
      lines = resolver.resolve_lines

      expect(lines[0][:amount_cents]).to eq(0)
    end
  end

  describe "#resolve_debits" do
    it "returns only debit lines" do
      account = create(:accounting_account)
      template = build(:accounting_entry_template)
      template.lines = [
        build(:accounting_entry_template_line, entry_template: template, account: account, direction: "debit", sequence_index: 1),
        build(:accounting_entry_template_line, entry_template: template, account: account, direction: "credit", sequence_index: 2)
      ]
      template.save!

      resolver = described_class.new(template, { amount: 100 })
      expect(resolver.resolve_debits.size).to eq(1)
      expect(resolver.resolve_debits[0][:direction]).to eq("debit")
    end
  end

  describe "#resolve_credits" do
    it "returns only credit lines" do
      account = create(:accounting_account)
      template = build(:accounting_entry_template)
      template.lines = [
        build(:accounting_entry_template_line, entry_template: template, account: account, direction: "debit", sequence_index: 1),
        build(:accounting_entry_template_line, entry_template: template, account: account, direction: "credit", sequence_index: 2)
      ]
      template.save!

      resolver = described_class.new(template, { amount: 100 })
      expect(resolver.resolve_credits.size).to eq(1)
      expect(resolver.resolve_credits[0][:direction]).to eq("credit")
    end
  end
end
