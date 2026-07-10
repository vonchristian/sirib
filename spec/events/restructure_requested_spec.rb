require "rails_helper"

RSpec.describe RestructureRequested do
  subject(:event) do
    described_class.new(
      aggregate: loan,
      actor: user,
      restructure_type: "modification",
      restructure_case_id: 1,
      proposed_changes: { interest_rate: "1.0", term_months: "18" }
    )
  end

  let(:loan) { create(:lending_loan) }
  let(:user) { create(:user) }

  it "has the correct event name" do
    expect(event.event_name).to eq("restructure_requested")
  end

  it "validates restructure_type" do
    event.restructure_type = nil
    expect(event).not_to be_valid
  end

  it "validates restructure_case_id" do
    event.restructure_case_id = nil
    expect(event).not_to be_valid
  end

  it "saves as a LoanEvent record" do
    record = event.save!
    expect(record.event_type).to eq("restructure_requested")
    expect(record.metadata["restructure_type"]).to eq("modification")
    expect(record.metadata["proposed_changes"]).to be_a(Hash)
  end

  it "includes proposed_changes in metadata" do
    record = event.save!
    expect(record.metadata["proposed_changes"]).to include("interest_rate" => "1.0")
  end
end
