require "rails_helper"

RSpec.describe Lending::LoanEvent do
  describe "associations" do
    it { is_expected.to belong_to(:loan) }
    it { is_expected.to belong_to(:actor) }
    it { is_expected.to belong_to(:cooperative) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[draft completed failed reversed]) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(Lending::LoanEvent::EVENT_TYPES) }
  end

  describe "scopes" do
    let!(:old_event) { create(:lending_loan_event, created_at: 1.day.ago, event_type: "restructure_requested") }
    let!(:new_event) { create(:lending_loan_event, created_at: 1.hour.ago, event_type: "restructure_approved") }

    it "orders chronologically" do
      expect(Lending::LoanEvent.chronological).to eq([ old_event, new_event ])
    end

    it "orders reverse chronologically" do
      expect(Lending::LoanEvent.reverse_chronological).to eq([ new_event, old_event ])
    end

    it "filters by event type" do
      expect(Lending::LoanEvent.by_type("restructure_requested")).to contain_exactly(old_event)
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:lending_loan_event)).to be_valid
    end
  end

end
