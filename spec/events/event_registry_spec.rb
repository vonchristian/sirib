require "rails_helper"

RSpec.describe "Event Registry" do
  it "maps all known event types to classes" do
    expect(EVENT_REGISTRY).to include(
      "loan_disbursed",
      "loan_payment_received",
      "loan_restructured",
      "loan_approved",
      "loan_closed",
      "loan_written_off",
      "restructure_requested",
      "restructure_approved",
      "restructure_rejected",
      "loan_link_created"
    )
  end

  it "maps each entry to a DomainEvent subclass" do
    EVENT_REGISTRY.each_value do |event_class|
      expect(event_class).to be < DomainEvent
    end
  end

  it "handles unknown event types gracefully" do
    expect(EVENT_REGISTRY["unknown_event"]).to be_nil
  end

  it "can replay events to reconstruct loan state" do
    allow(Lending::AgingCalculationService).to receive(:call)
    loan = create(:lending_loan,
      principal_cents: 100000,
      outstanding_principal_cents: 100000,
      status: "active",
      interest_rate: 5.0,
      term_months: 12
    )
    user = create(:user)

    event_records = [
      LoanDisbursed.new(
        aggregate: loan, actor: user,
        amount_cents: 100000, disbursement_method: "cash", disbursed_to_account_id: 1
      ).save!,
      LoanPaymentReceived.new(
        aggregate: loan, actor: user,
        amount_cents: 5000, principal_cents: 3000, interest_cents: 1500, penalty_cents: 500,
        payment_method: "cash"
      ).save!,
      LoanPaymentReceived.new(
        aggregate: loan, actor: user,
        amount_cents: 5000, principal_cents: 3000, interest_cents: 1500, penalty_cents: 500,
        payment_method: "cash"
      ).save!
    ]

    loan.update!(outstanding_principal_cents: 100000, disbursed_at: nil)

    event_records.each do |record|
      event_class = EVENT_REGISTRY[record.event_type]
      event = event_class.new(
        aggregate: loan,
        actor: record.actor,
        **record.metadata.symbolize_keys
      )
      event.replay(loan)
    end

    loan.reload
    expect(loan.outstanding_principal_cents).to eq(94000)
  end

  it "handles unknown event types gracefully during replay" do
    lookup = EVENT_REGISTRY["unknown_event"]
    expect(lookup).to be_nil
  end
end
