require "rails_helper"

RSpec.describe Reconciliation::EntryStatusCheck do
  it "passes when all reversed entries have reversed_at set" do
    create(:accounting_entry, status: :reversed, reversed_at: Time.current)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "detects entries missing reversed_at" do
    entry = create(:accounting_entry, status: :reversed, reversed_at: nil)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).not_to be_empty
    expect(failures.first[:resource_id]).to eq(entry.id)
  end

  it "ignores non-reversed entries" do
    create(:accounting_entry, status: :posted)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "records a result record after running" do
    described_class.run!(as_of_date: Date.current)
    result = Reconciliation::Result.last
    expect(result.check_name).to eq("EntryStatusCheck")
  end
end
