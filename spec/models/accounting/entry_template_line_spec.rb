require "rails_helper"

RSpec.describe Accounting::EntryTemplateLine do
  describe "associations" do
    it { is_expected.to belong_to(:entry_template) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:direction) }
    it { is_expected.to validate_presence_of(:amount_mode) }
    it { is_expected.to validate_presence_of(:sequence_index) }
  end

  describe "scopes" do
    let!(:template) { create(:accounting_entry_template) }

    describe ".debits" do
      it "returns only debit lines" do
        debit = template.lines.debits.first
        expect(template.lines.debits).to include(debit)
      end
    end

    describe ".credits" do
      it "returns only credit lines" do
        credit = template.lines.credits.first
        expect(template.lines.credits).to include(credit)
      end
    end
  end
end
