require "rails_helper"

RSpec.describe LoanWrittenOff do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      written_off_by_id: user.id,
      reason: "default",
      amount_cents: 50000,
      approval_reference: "BOARD-2026-001"
    )
  end

  let(:loan) { create(:lending_loan, status: "active", outstanding_principal_cents: 50000) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_written_off")
  end

  it "validates written_off_by_id" do
    event.written_off_by_id = nil
    expect(event).not_to be_valid
  end

  it "validates amount_cents" do
    event.amount_cents = 0
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("loan_written_off")
  end

  it "replays on loan" do
    allow(Lending::AgingCalculationService).to receive(:call)
    event.replay(loan)
    loan.reload
    expect(loan.status).to eq("written_off")
    expect(loan.outstanding_principal_cents).to eq(0)
  end
end
