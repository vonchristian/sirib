require "rails_helper"

RSpec.describe Lending::AgingCalculationService do
  describe ".call" do
    subject(:call) { described_class.call(loan: loan, as_of: as_of) }

    let(:cooperative) { create(:cooperative) }
    let(:as_of) { Date.current }
    let(:loan) { create(:lending_loan, cooperative: cooperative, principal_cents: 100_000_00, outstanding_principal_cents: 90_000_00) }
    let(:current_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "Current", min_days: 0, max_days: 0, display_order: 0) }
    let(:past_due_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "1-30 Days", min_days: 1, max_days: 30, display_order: 1) }
    let(:overdue_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "31-60 Days", min_days: 31, max_days: 60, display_order: 2) }

    before do
      current_group
      past_due_group
      overdue_group
    end

    context "when loan has no unpaid schedules" do
      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 30.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_payment, cooperative: cooperative,
          loan: loan, principal_cents: 10_000_00, interest_cents: 1_500_00,
          amount_cents: 11_500_00, payment_date: 20.days.ago)
      end

      it "assigns DPD 0" do
        expect(call.days_past_due).to eq(0)
      end

      it "assigns Current bucket" do
        expect(call.loan_aging_group).to eq(current_group)
      end

      it "sets oldest_unpaid_due_date to nil" do
        expect(call.oldest_unpaid_due_date).to be_nil
      end
    end

    context "when loan has overdue schedules" do
      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 15.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 2,
          due_date: 15.days.from_now, principal_cents: 10_000_00, interest_cents: 1_500_00)
      end

      it "calculates DPD correctly" do
        expect(call.days_past_due).to eq(15)
      end

      it "assigns correct aging bucket" do
        expect(call.loan_aging_group).to eq(past_due_group)
      end

      it "sets oldest_unpaid_due_date" do
        expect(call.oldest_unpaid_due_date).to eq(15.days.ago.to_date)
      end
    end

    context "with partial payment" do
      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 45.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 2,
          due_date: 15.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_payment, cooperative: cooperative,
          loan: loan, principal_cents: 5_000_00, interest_cents: 1_500_00,
          amount_cents: 6_500_00, payment_date: 20.days.ago)
      end

      it "finds oldest partially paid schedule" do
        expect(call.days_past_due).to eq(45)
        expect(call.oldest_unpaid_due_date).to eq(45.days.ago.to_date)
      end

      it "assigns bucket based on oldest partially paid" do
        expect(call.loan_aging_group).to eq(overdue_group)
      end
    end

    context "with fully paid first schedule" do
      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 45.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 2,
          due_date: 15.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_payment, cooperative: cooperative,
          loan: loan, principal_cents: 10_000_00, interest_cents: 1_500_00,
          amount_cents: 11_500_00, payment_date: 20.days.ago)
      end

      it "finds next unpaid schedule" do
        expect(call.days_past_due).to eq(15)
        expect(call.loan_aging_group).to eq(past_due_group)
      end
    end

    context "with severely overdue loan" do
      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 45.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
      end

      it "calculates higher DPD" do
        expect(call.days_past_due).to eq(45)
      end

      it "assigns higher bucket" do
        expect(call.loan_aging_group).to eq(overdue_group)
      end
    end

    context "with multiple unpaid schedules" do
      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 60.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 2,
          due_date: 30.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
      end

      it "uses oldest unpaid schedule date" do
        expect(call.days_past_due).to eq(60)
      end
    end

    it "updates existing record instead of creating duplicate" do
      initial = described_class.call(loan: loan, as_of: as_of)
      expect do
        described_class.call(loan: loan, as_of: as_of + 10.days)
      end.not_to change(Lending::LoanAging, :count)

      expect(initial.reload.days_past_due).to eq(0)
    end
  end

  describe ".refresh_all" do
    it "recalculates aging for all active loans" do
      cooperative = create(:cooperative)
      group = create(:lending_loan_aging_group, cooperative: cooperative, name: "Current", min_days: 0, max_days: 0)
      loan1 = create(:lending_loan, cooperative: cooperative, status: "active")
      loan2 = create(:lending_loan, cooperative: cooperative, status: "active")
      create(:lending_loan, cooperative: cooperative, status: "paid")

      expect { described_class.refresh_all }.to change(Lending::LoanAging, :count).by(2)
    end
  end
end
