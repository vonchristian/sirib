require "rails_helper"

RSpec.describe LoanApproved do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      approved_by_id: user.id,
      approval_date: Date.current,
      approved_amount_cents: 100000,
      notes: "Approved"
    )
  end

  let(:loan) { create(:lending_loan, status: "active") }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("loan_approved")
  end

  it "validates approved_by_id" do
    event.approved_by_id = nil
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("loan_approved")
  end
end
