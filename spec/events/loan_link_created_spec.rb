require "rails_helper"

RSpec.describe LoanLinkCreated do
  subject(:event) do
    described_class.new(
      aggregate: from_loan,
      actor: user,
      link_id: 1,
      link_type: "refinance",
      from_loan_id: from_loan.id,
      to_loan_id: to_loan.id,
      amount_cents: 50000
    )
  end

  let(:from_loan) { create(:lending_loan) }
  let(:to_loan) { create(:lending_loan) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_link_created")
  end

  it "validates link_type" do
    event.link_type = nil
    expect(event).not_to be_valid
  end

  it "validates from_loan_id" do
    event.from_loan_id = nil
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("loan_link_created")
    expect(record.metadata["link_type"]).to eq("refinance")
    expect(record.metadata["amount_cents"]).to eq(50000)
  end
end
