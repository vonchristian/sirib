require "rails_helper"

RSpec.describe Accounting::EntryTemplate do
  describe "associations" do
    it { is_expected.to have_many(:lines).dependent(:destroy) }
    it { is_expected.to belong_to(:entry).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "factory" do
    it "creates a valid record" do
      template = build(:accounting_entry_template)
      expect(template).to be_valid
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active templates" do
        active = create(:accounting_entry_template, is_active: true)
        create(:accounting_entry_template, is_active: false)

        expect(described_class.active).to contain_exactly(active)
      end
    end
  end

  describe "#execute!" do
    it "delegates to ExecuteService" do
      template = build(:accounting_entry_template)
      service = instance_double(Accounting::EntryTemplate::ExecuteService)
      allow(Accounting::EntryTemplate::ExecuteService).to receive(:run!).and_return(service)

      template.execute!(amount: 1000)

      expect(Accounting::EntryTemplate::ExecuteService).to have_received(:run!).with(template: template, amount: 1000, user: nil)
    end
  end

  describe "#preview" do
    it "delegates to ExecuteService" do
      template = build(:accounting_entry_template)
      allow(Accounting::EntryTemplate::ExecuteService).to receive(:run).and_return([])

      template.preview(amount: 1000)

      expect(Accounting::EntryTemplate::ExecuteService).to have_received(:run).with(template: template, amount: 1000)
    end
  end
end
