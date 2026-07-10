require "rails_helper"

RSpec.describe Reconciliation::LoanPrincipalIntegrityCheck do
  before do
    allow(Lending::AgingCalculationService).to receive(:call)
  end

  it "passes when loan principal is intact" do
    create(:lending_loan, principal_cents: 100_000_00, outstanding_principal_cents: 100_000_00)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "detects principal mismatch" do
    loan = create(:lending_loan, principal_cents: 100_000_00, outstanding_principal_cents: 50_000_00)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).not_to be_empty
    expect(failures.first[:resource_id]).to eq(loan.id)
  end

  it "records a result record after running" do
    described_class.run!(as_of_date: Date.current)
    result = Reconciliation::Result.last
    expect(result.check_name).to eq("LoanPrincipalIntegrityCheck")
  end

  it "reports total_count correctly" do
    create_list(:lending_loan, 2, principal_cents: 100_000_00, outstanding_principal_cents: 100_000_00)
    check = described_class.new(as_of_date: Date.current)
    expect(check.send(:total_count)).to eq(2)
  end
end
