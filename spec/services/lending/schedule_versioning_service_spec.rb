require "rails_helper"

RSpec.describe Lending::ScheduleVersioningService do
  describe ".call" do
    subject(:create_schedule) do
      described_class.call(loan: loan, new_schedule_data: new_data, supersede_existing: supersede)
    end

    let(:loan) { create(:lending_loan) }
    let(:new_data) { [ { "sequence" => 1, "due_date" => Date.current.next_month.to_s, "principal_cents" => 10_000_00, "interest_cents" => 1_000_00 } ] }
    let(:supersede) { true }

    context "with no existing schedules" do
      it "creates a new schedule with version 1" do
        expect { create_schedule }.to change(Lending::LoanSchedule, :count).by(1)
        expect(create_schedule.version).to eq(1)
        expect(create_schedule).to be_active
      end
    end

    context "with existing active schedule" do
      let!(:existing) { create(:lending_loan_schedule, loan: loan, version: 1, status: "active") }

      it "supersedes the old schedule" do
        create_schedule
        expect(existing.reload).to be_superseded
        expect(existing.superseded_at).to be_present
      end

      it "creates the next version" do
        expect(create_schedule.version).to eq(2)
      end
    end

    context "when supersede_existing is false" do
      let(:supersede) { false }

      it "does not supersede existing schedules" do
        existing = create(:lending_loan_schedule, loan: loan, version: 1, status: "active")
        create_schedule
        expect(existing.reload).to be_active
      end
    end
  end
end
