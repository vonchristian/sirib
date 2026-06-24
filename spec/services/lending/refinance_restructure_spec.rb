require "rails_helper"

RSpec.describe Lending::RefinanceRestructure do
  subject(:strategy) { described_class.new(loan, changes) }

  let(:loan) do
    create(:lending_loan, principal_cents: 75_000_00, outstanding_principal_cents: 75_000_00, interest_rate: 1.5, term_months: 12)
  end
  let(:changes) { { "interest_rate" => "1.25", "term_months" => "24" } }

  describe "#simulate" do
    subject(:simulation) { strategy.simulate }

    it "returns refinance type" do
      expect(simulation[:type]).to eq("refinance")
    end

    it "calculates payoff" do
      expect(simulation[:payoff_amount]).to be_present
      expect(simulation[:payoff_breakdown]).to include(:outstanding_principal, :accrued_interest, :penalties)
    end

    it "calculates new loan terms" do
      expect(simulation[:new_interest_rate]).to eq(1.25)
      expect(simulation[:new_term_months]).to eq(24)
    end

    it "generates a proposed schedule" do
      expect(simulation[:proposed_schedule]).to be_an(Array)
    end
  end

  describe "#execute!" do
    subject(:execution) { strategy.execute! }

    let!(:user) { create(:user) }

    it "creates a new loan" do
      loan # ensure loan is created first
      count_before = Lending::Loan.count
      execution
      expect(Lending::Loan.count - count_before).to eq(1)
    end

    it "creates a loan link" do
      expect { execution }.to change(Lending::LoanLink, :count).by(1)
    end

    it "marks old loan as refinanced" do
      execution
      expect(loan.reload.status).to eq("refinanced")
    end

    it "creates a payment for the payoff" do
      expect { execution }.to change { loan.loan_payments.count }.by(1)
    end

    it "sets old loan outstanding to zero" do
      execution
      expect(loan.reload.outstanding_principal_cents).to eq(0)
    end
  end
end
