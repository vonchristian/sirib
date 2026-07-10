require "rails_helper"

RSpec.describe LoanRestructured do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      new_principal_cents: 80000,
      new_term_months: 18,
      new_interest_rate: 4.5,
      old_principal_cents: 100000,
      reason: "hardship"
    )
  end

  let(:loan) { create(:lending_loan, principal_cents: 100000, term_months: 12, interest_rate: 5.0, outstanding_principal_cents: 90000) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_restructured")
  end

  it "validates new_principal_cents" do
    event.new_principal_cents = 0
    expect(event).not_to be_valid
  end

  it "validates new_term_months" do
    event.new_term_months = 0
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("loan_restructured")
    expect(record.metadata["new_principal_cents"]).to eq(80000)
  end

  it "replays on loan" do
    event.replay(loan)
    loan.reload
    expect(loan.principal_cents).to eq(80000)
    expect(loan.term_months).to eq(18)
    expect(loan.interest_rate).to eq(4.5)
    expect(loan.outstanding_principal_cents).to eq(80000)
  end
end
