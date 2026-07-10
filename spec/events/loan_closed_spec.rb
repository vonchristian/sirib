require "rails_helper"

RSpec.describe LoanClosed do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      closed_by_id: user.id,
      reason: "fully_paid",
      final_principal_cents: 0,
      final_interest_cents: 0
    )
  end

  let(:loan) { create(:lending_loan, status: "active") }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_closed")
  end

  it "validates closed_by_id" do
    event.closed_by_id = nil
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("loan_closed")
  end

  it "replays on loan" do
    allow(Lending::AgingCalculationService).to receive(:call)
    event.replay(loan)
    loan.reload
    expect(loan.status).to eq("paid")
  end
end
