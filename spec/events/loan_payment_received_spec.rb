require "rails_helper"

RSpec.describe LoanPaymentReceived do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      amount_cents: 5000,
      principal_cents: 3000,
      interest_cents: 1500,
      penalty_cents: 500,
      payment_method: "cash"
    )
  end

  let(:loan) { create(:lending_loan, outstanding_principal_cents: 100000) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_payment_received")
  end

  it "validates amount_cents" do
    event.amount_cents = 0
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("loan_payment_received")
    expect(record.metadata["principal_cents"]).to eq(3000)
  end

  it "replays on loan and reduces outstanding principal" do
    event.replay(loan)
    loan.reload
    expect(loan.outstanding_principal_cents).to eq(97000)
  end

  it "replay does not go below zero" do
    event.principal_cents = 200000
    event.replay(loan)
    loan.reload
    expect(loan.outstanding_principal_cents).to eq(0)
  end
end
