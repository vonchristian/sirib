require "rails_helper"

RSpec.describe Reconciliation::RunningBalanceAccuracyCheck do
  it "passes when running balances match computed balances" do
    account = create(:accounting_account, account_type: "asset")
    entry = create(:accounting_entry, posted_at: Time.current)
    AppendOnlyOverride.with_override(reason: "test setup") do
      entry.amount_lines.first.update!(account: account)
      entry.amount_lines.last.update!(account: account)
    end

    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "passes when no running balance record exists" do
    create(:accounting_account)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "records a result record after running" do
    described_class.run!(as_of_date: Date.current)
    result = Reconciliation::Result.last
    expect(result.check_name).to eq("RunningBalanceAccuracyCheck")
  end

  it "reports total_count correctly" do
    create_list(:accounting_account, 2)
    check = described_class.new(as_of_date: Date.current)
    expect(check.send(:total_count)).to eq(2)
  end
end
