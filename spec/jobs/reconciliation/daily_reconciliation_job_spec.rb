require "rails_helper"

RSpec.describe Reconciliation::DailyReconciliationJob do
  it "runs all 5 checks for each cooperative" do
    coop_count = Cooperative.count

    expect(Reconciliation::DebitsEqualCreditsCheck).to receive(:run!)
      .exactly(coop_count).times
    expect(Reconciliation::RunningBalanceAccuracyCheck).to receive(:run!)
      .exactly(coop_count).times
    expect(Reconciliation::LoanPrincipalIntegrityCheck).to receive(:run!)
      .exactly(coop_count).times
    expect(Reconciliation::PaymentAllocationCheck).to receive(:run!)
      .exactly(coop_count).times
    expect(Reconciliation::EntryStatusCheck).to receive(:run!)
      .exactly(coop_count).times

    described_class.perform_now
  end

  it "runs checks for each additional cooperative" do
    create(:cooperative)
    coop_count = Cooperative.count

    expect(Reconciliation::DebitsEqualCreditsCheck).to receive(:run!)
      .exactly(coop_count).times

    described_class.perform_now
  end

  it "passes as_of_date: Date.yesterday to each check" do
    expect(Reconciliation::DebitsEqualCreditsCheck).to receive(:run!).with(
      hash_including(as_of_date: Date.yesterday)
    ).at_least(:once)

    described_class.perform_now
  end

  it "enqueues on the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
