Rails.application.config.to_prepare do
  EVENT_REGISTRY = {
    "loan_disbursed" => LoanDisbursed,
    "loan_payment_received" => LoanPaymentReceived,
    "loan_restructured" => LoanRestructured,
    "loan_approved" => LoanApproved,
    "loan_closed" => LoanClosed,
    "loan_written_off" => LoanWrittenOff,
    "restructure_requested" => RestructureRequested,
    "restructure_approved" => RestructureApproved,
    "restructure_rejected" => RestructureRejected,
    "loan_link_created" => LoanLinkCreated
  }.freeze
end
