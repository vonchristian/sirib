require "rails_helper"

RSpec.describe Lending::LoanPayoffService do
  describe ".call" do
    subject(:payoff) { described_class.call(loan: loan, as_of: Date.current) }

    let(:loan) { create(:lending_loan, principal_cents: 100_000_00, outstanding_principal_cents: 75_000_00) }
    let(:cooperative) { loan.cooperative }

    before do
      create(:lending_loan_repayment_schedule, cooperative: cooperative,
        loan_application: loan.loan_application, sequence: 1,
        due_date: 15.days.ago, principal_cents: 8_333_33, interest_cents: 1_250_00)
      create(:lending_loan_repayment_schedule, cooperative: cooperative,
        loan_application: loan.loan_application, sequence: 2,
        due_date: Date.current.next_month, principal_cents: 8_333_33, interest_cents: 1_250_00)
    end

    it "calculates outstanding principal" do
      expect(payoff[:outstanding_principal_cents]).to eq(100_000_00)
    end

    it "includes total payoff amount" do
      expect(payoff[:total_payoff_cents]).to be > 0
    end

    it "returns a hash with expected keys" do
      expected_keys = %i[outstanding_principal_cents accrued_interest_cents overdue_interest_cents
        penalty_cents total_payoff_cents paid_principal_cents paid_interest_cents paid_penalties_cents as_of]
      expect(payoff.keys).to match_array(expected_keys)
    end

    context "with partial payments" do
      before do
        create(:lending_loan_payment, cooperative: cooperative,
          loan: loan, principal_cents: 10_000_00, interest_cents: 1_250_00,
          penalty_cents: 0, amount_cents: 11_250_00, payment_date: 10.days.ago)
      end

      it "reduces outstanding principal" do
        expect(payoff[:paid_principal_cents]).to eq(10_000_00)
      end
    end

    context "with fully paid loan" do
      before do
        create(:lending_loan_payment, cooperative: cooperative,
          loan: loan, principal_cents: 100_000_00, interest_cents: 2_500_00,
          penalty_cents: 0, amount_cents: 102_500_00, payment_date: 10.days.ago)
      end

      it "returns zero payoff" do
        expect(payoff[:total_payoff_cents]).to eq(0)
      end
    end
  end
end
