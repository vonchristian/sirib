require "rails_helper"

RSpec.describe Lending::ModificationRestructure do
  subject(:strategy) { described_class.new(loan, changes) }

  let(:loan) do
    create(:lending_loan, outstanding_principal_cents: 75_000_00, interest_rate: 1.5, term_months: 12)
  end
  let(:changes) { { "interest_rate" => "1.0", "term_months" => "18", "grace_period_months" => "3" } }

  describe "#simulate" do
    subject(:simulation) { strategy.simulate }

    it "returns modification type" do
      expect(simulation[:type]).to eq("modification")
    end

    it "applies the new rate and term" do
      expect(simulation[:new_interest_rate]).to eq(1.0)
      expect(simulation[:new_term_months]).to eq(18)
    end

    it "calculates payment comparison" do
      expect(simulation[:old_monthly_payment]).to be_present
      expect(simulation[:new_monthly_payment]).to be_present
      expect(simulation[:payment_change]).to be_present
    end

    it "generates a proposed schedule" do
      expect(simulation[:proposed_schedule]).to be_an(Array)
      expect(simulation[:proposed_schedule].length).to eq(18)
    end
  end

  describe "#execute!" do
    subject(:execution) { strategy.execute! }

    before do
      create(:lending_loan_schedule, loan: loan, version: 1, status: "active")
    end

    it "creates a new schedule version" do
      expect { execution }.to change { loan.loan_schedules.count }.by(1)
    end

    it "updates loan status to modified" do
      execution
      expect(loan.reload.status).to eq("modified")
    end

    it "supersedes the old schedule" do
      execution
      expect(loan.loan_schedules.where(version: 1).first).to be_superseded
    end
  end
end
