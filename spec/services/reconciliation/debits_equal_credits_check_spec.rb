require "rails_helper"

RSpec.describe Reconciliation::DebitsEqualCreditsCheck do
  it "passes when all entries are balanced" do
    create(:accounting_entry)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "detects unbalanced entries" do
    entry = create(:accounting_entry)
    AppendOnlyOverride.with_override(reason: "test setup") do
      entry.amount_lines.first.update!(amount_cents: 500)
    end

    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).not_to be_empty
    expect(failures.first[:resource_id]).to eq(entry.id)
  end

  it "records a result record after running" do
    create(:accounting_entry)
    described_class.run!(as_of_date: Date.current)
    result = Reconciliation::Result.last
    expect(result.check_name).to eq("DebitsEqualCreditsCheck")
    expect(result.status).to eq("passed")
  end

  it "creates a critical alert on failure" do
    entry = create(:accounting_entry)
    AppendOnlyOverride.with_override(reason: "test setup") do
      entry.amount_lines.first.update!(amount_cents: 500)
    end

    expect do
      described_class.run!(as_of_date: Date.current)
    end.to change(Management::Alert, :count).by(1)

    alert = Management::Alert.last
    expect(alert.severity).to eq("critical")
    expect(alert.alert_type).to eq("reconciliation_failure")
  end

  it "scopes by cooperative when provided" do
    coop1 = create(:cooperative)
    coop2 = create(:cooperative)
    create(:accounting_entry, cooperative: coop1)
    create(:accounting_entry, cooperative: coop2)

    failures = described_class.run!(cooperative: coop1, as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "reports total_count correctly" do
    create_list(:accounting_entry, 3)
    check = described_class.new(as_of_date: Date.current)
    expect(check.send(:total_count)).to eq(3)
  end
end
