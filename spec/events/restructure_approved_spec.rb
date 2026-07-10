require "rails_helper"

RSpec.describe RestructureApproved do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      restructure_case_id: 1,
      approved_by: user.id,
      source: "management"
    )
  end

  let(:loan) { create(:lending_loan) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("restructure_approved")
  end

  it "validates restructure_case_id" do
    event.restructure_case_id = nil
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("restructure_approved")
    expect(record.metadata["source"]).to eq("management")
  end
end
