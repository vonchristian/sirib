require "rails_helper"

RSpec.describe Lending::HybridRestructure do
  subject(:strategy) { described_class.new(loan, changes) }

  let(:loan) do
    create(:lending_loan, outstanding_principal_cents: 75_000_00, interest_rate: 1.5, term_months: 12)
  end
  let(:changes) { { "interest_rate" => "1.0", "term_months" => "18", "arrears_cents" => "5000_00", "partial_payoff_cents" => "10_000_00" } }

  describe "#simulate" do
    subject(:simulation) { strategy.simulate }

    it "returns hybrid type" do
      expect(simulation[:type]).to eq("hybrid")
    end

    it "calculates arrears capitalization" do
      expect(simulation[:arrears_capitalized_cents]).to be_present
    end

    it "calculates new principal" do
      expect(simulation[:new_principal_cents]).to be_present
    end

    it "generates a proposed schedule" do
      expect(simulation[:proposed_schedule]).to be_an(Array)
    end
  end

  describe "#execute!" do
    subject(:execution) { strategy.execute! }

    let!(:user) { create(:user) }

    context "when creating a new loan" do
      let(:changes) { { "interest_rate" => "1.0", "term_months" => "18", "new_loan" => true } }

      it "creates a new loan" do
        count_before = Lending::Loan.count
        execution
        expect(Lending::Loan.count - count_before).to eq(2)
      end

      it "creates a loan link" do
        expect { execution }.to change(Lending::LoanLink, :count).by(1)
      end

      it "marks old loan as hybrid_restructured" do
        execution
        expect(loan.reload.status).to eq("hybrid_restructured")
      end
    end

    context "when modifying existing loan" do
      it "does not create a new loan" do
        loan # ensure loan is created first
        expect { execution }.not_to change(Lending::Loan, :count)
      end

      it "updates the loan status" do
        execution
        expect(loan.reload.status).to eq("hybrid_restructured")
      end

      it "creates a schedule version" do
        expect { execution }.to change(Lending::LoanSchedule, :count).by(1)
      end
    end
  end
end
