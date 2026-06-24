require "rails_helper"

RSpec.describe Lending::LoanLinkService do
  describe ".call" do
    subject(:create_link) do
      described_class.call(from_loan: from_loan, to_loan: to_loan, link_type: "refinance", amount_cents: 50_000_00, reason: "Test refinance")
    end

    let(:from_loan) { create(:lending_loan) }
    let(:to_loan) { create(:lending_loan) }
    let!(:user) { create(:user) }

    it "creates a loan link" do
      expect { create_link }.to change(Lending::LoanLink, :count).by(1)
    end

    it "creates a loan event" do
      expect { create_link }.to change(Lending::LoanEvent, :count).by(1)
    end

    it "sets the correct link type" do
      link = create_link
      expect(link.link_type).to eq("refinance")
      expect(link.amount_cents).to eq(50_000_00)
    end

    it "associates the loans correctly" do
      link = create_link
      expect(link.from_loan).to eq(from_loan)
      expect(link.to_loan).to eq(to_loan)
    end
  end
end
