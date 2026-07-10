require "rails_helper"

RSpec.describe LoanDisbursed do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      amount_cents: 100000,
      disbursement_method: "cash",
      disbursed_to_account_id: 1
    )
  end

  let(:loan) { create(:lending_loan, status: "active", outstanding_principal_cents: 100000) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_disbursed")
  end

  it "validates amount_cents" do
    event.amount_cents = 0
    expect(event).not_to be_valid
  end

  it "validates disbursement_method" do
    event.disbursement_method = nil
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record).to be_a(Lending::LoanEvent)
    expect(record.event_type).to eq("loan_disbursed")
    expect(record.metadata["amount_cents"]).to eq(100000)
    expect(record.metadata["disbursement_method"]).to eq("cash")
  end

  it "replays on loan" do
    event.replay(loan)
    loan.reload
    expect(loan.outstanding_principal_cents).to eq(100000)
    expect(loan.disbursed_at).to be_present
    expect(loan.status).to eq("active")
  end
end
