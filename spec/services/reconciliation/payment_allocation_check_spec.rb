require "rails_helper"

RSpec.describe Reconciliation::PaymentAllocationCheck do
  before do
    allow(Lending::AgingCalculationService).to receive(:call)
  end

  it "passes when all payments are properly allocated" do
    loan = create(:lending_loan)
    create(:lending_loan_payment, loan: loan)
    failures = described_class.run!(as_of_date: Date.current)
    expect(failures).to be_empty
  end

  it "reports total_count correctly" do
    loan = create(:lending_loan)
    create(:lending_loan_payment, loan: loan)
    check = described_class.new(as_of_date: Date.current)
    expect(check.send(:total_count)).to eq(1)
  end

  it "records a result record after running" do
    described_class.run!(as_of_date: Date.current)
    result = Reconciliation::Result.last
    expect(result.check_name).to eq("PaymentAllocationCheck")
  end
end
