module Lending
  class LoanLinkService
    def self.call(from_loan:, to_loan:, link_type:, amount_cents: 0, reason: nil)
      new(from_loan, to_loan, link_type, amount_cents, reason).call
    end

    def initialize(from_loan, to_loan, link_type, amount_cents, reason)
      @from_loan = from_loan
      @to_loan = to_loan
      @link_type = link_type
      @amount_cents = amount_cents
      @reason = reason
    end

    def call
      Lending::LoanLink.transaction do
        link = Lending::LoanLink.create!(
          cooperative: @from_loan.cooperative,
          from_loan: @from_loan,
          to_loan: @to_loan,
          link_type: @link_type,
          amount_cents: @amount_cents,
          amount_currency: "PHP",
          reason: @reason
        )

        Lending::LoanEvent.create!(
          cooperative: @from_loan.cooperative,
          loan: @from_loan,
          actor: Current.user || User.first,
          event_type: "loan_link_created",
          metadata: {
            link_id: link.id,
            link_type: @link_type,
            from_loan_id: @from_loan.id,
            to_loan_id: @to_loan.id,
            amount_cents: @amount_cents
          }
        )

        link
      end
    end
  end
end
