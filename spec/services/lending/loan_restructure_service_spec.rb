require "rails_helper"

RSpec.describe Lending::LoanRestructureService do
  describe ".call" do
    subject(:create_case) do
      described_class.call(type: type, loan: loan, proposed_changes: changes, requested_by: user)
    end

    let(:loan) { create(:lending_loan, status: "active", restructures_count: 0, max_restructures: 2) }
    let(:user) { create(:user) }
    let(:changes) { { "interest_rate" => "1.0", "term_months" => "18" } }
    let(:type) { "modification" }

    it "creates a restructure case" do
      expect { create_case }.to change(Lending::LoanRestructureCase, :count).by(1)
    end

    it "creates a loan event" do
      expect { create_case }.to change(Lending::LoanEvent, :count).by(1)
    end

    it "sets the correct type" do
      expect(create_case.restructure_type).to eq("modification")
    end

    it "sets status to draft" do
      expect(create_case).to be_draft
    end

    context "when loan is not restructurable" do
      let(:loan) { create(:lending_loan, status: "paid", restructures_count: 0, max_restructures: 2) }

      it "raises an error" do
        expect { create_case }.to raise_error("Loan cannot be restructured")
      end
    end

    context "when max restructures reached" do
      let(:loan) { create(:lending_loan, status: "active", restructures_count: 2, max_restructures: 2) }

      it "raises an error" do
        expect { create_case }.to raise_error("Loan cannot be restructured")
      end
    end

    context "with refinance type" do
      let(:type) { "refinance" }

      it "creates a refinance case" do
        expect(create_case).to be_refinance
      end
    end

    context "with hybrid type" do
      let(:type) { "hybrid" }

      it "creates a hybrid case" do
        expect(create_case).to be_hybrid
      end
    end
  end

  describe "#simulate" do
    subject(:simulation) do
      described_class.new(type, loan, changes, nil, {}).simulate
    end

    let(:loan) { create(:lending_loan, status: "active", outstanding_principal_cents: 75_000_00, restructures_count: 0) }

    context "with modification" do
      let(:type) { "modification" }
      let(:changes) { { "interest_rate" => "1.0", "term_months" => "18" } }

      it "returns simulation data" do
        expect(simulation[:type]).to eq("modification")
        expect(simulation[:new_interest_rate]).to eq(1.0)
        expect(simulation[:new_term_months]).to eq(18)
        expect(simulation[:new_monthly_payment]).to be_present
        expect(simulation[:proposed_schedule]).to be_an(Array)
      end
    end

    context "with refinance" do
      let(:type) { "refinance" }
      let(:changes) { { "interest_rate" => "1.25", "term_months" => "24" } }

      it "returns simulation data with payoff" do
        expect(simulation[:type]).to eq("refinance")
        expect(simulation[:payoff_amount]).to be_present
        expect(simulation[:new_principal]).to be_present
      end
    end
  end

  describe "#execute" do
    let(:service) { described_class.new("modification", loan, changes, nil, {}) }
    let(:loan) { create(:lending_loan, status: "active", outstanding_principal_cents: 75_000_00, restructures_count: 0, max_restructures: 2) }
    let(:changes) { { "interest_rate" => "1.0", "term_months" => "18" } }
    let!(:user) { create(:user) }

    context "with approved case" do
      let(:restructure_case) do
        create(:lending_loan_restructure_case, loan: loan, restructure_type: "modification", status: "approved")
      end

      it "executes the restructure" do
        result = service.execute(restructure_case: restructure_case)
        expect(result[:new_status]).to eq("modified")
      end

      it "increments restructures count" do
        expect { service.execute(restructure_case: restructure_case) }
          .to change { loan.reload.restructures_count }.by(1)
      end
    end

    context "with unapproved case" do
      let(:restructure_case) do
        create(:lending_loan_restructure_case, loan: loan, restructure_type: "modification", status: "draft")
      end

      it "raises error" do
        expect { service.execute(restructure_case: restructure_case) }.to raise_error("Case not approved")
      end
    end
  end
end
