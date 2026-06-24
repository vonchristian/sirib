puts "\n  → Seeding restructure cases..."

coop = @coop
member = Membership::Member.where(cooperative: coop).first
loan_product = Lending::LoanProduct.where(cooperative: coop).first
loan_app = Lending::LoanApplication.where(cooperative: coop, member: member).first

if member && loan_product && loan_app
  loan = Lending::Loan.find_or_create_by!(
    reference_number: "LN-REST-DEMO-001",
    cooperative: coop
  ) do |l|
    l.loan_application = loan_app
    l.member = member
    l.loan_product = loan_product
    l.principal_cents = 100_000_00
    l.interest_rate = 1.5
    l.interest_calculation = "declining_balance"
    l.term_months = 12
    l.outstanding_principal_cents = 75_000_00
    l.status = "active"
    l.disbursed_at = 6.months.ago
  end

  user = User.where(cooperative: coop).first

  unless Lending::LoanRestructureCase.exists?(loan: loan, restructure_type: "modification")
    modification_case = Lending::LoanRestructureCase.create!(
      loan: loan,
      restructure_type: "modification",
      status: "submitted",
      proposed_changes: {
        interest_rate: "1.0",
        term_months: "18",
        grace_period_months: "3"
      },
      notes: "Member requested lower interest rate due to financial hardship.",
      requested_by: user,
      submitted_at: Time.current,
      cooperative: coop
    )

    Lending::LoanEvent.create!(
      loan: loan,
      actor: user,
      event_type: "restructure_requested",
      metadata: { restructure_type: "modification", restructure_case_id: modification_case.id },
      cooperative: coop
    )

    Lending::LoanEvent.create!(
      loan: loan,
      actor: user,
      event_type: "restructure_submitted",
      metadata: { restructure_case_id: modification_case.id },
      cooperative: coop
    )
  end

  unless Lending::LoanRestructureCase.exists?(loan: loan, restructure_type: "refinance")
    Lending::LoanRestructureCase.create!(
      loan: loan,
      restructure_type: "refinance",
      status: "draft",
      proposed_changes: {
        interest_rate: "1.25",
        term_months: "24"
      },
      notes: "Refinance to lower monthly payments.",
      requested_by: user,
      cooperative: coop
    )
  end

  puts "  → Restructure seed data created for #{coop.name}"
else
  puts "  → Skipping restructure seed for #{coop.name} (missing prerequisites)"
end
