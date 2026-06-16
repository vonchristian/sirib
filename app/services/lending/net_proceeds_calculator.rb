module Lending
  class NetProceedsCalculator
    def self.call(loan_product:, amount_cents:)
      charges = loan_product.loan_charges.ordered.map do |charge|
        computed = charge.computed_cents(amount_cents)
        { name: charge.name, charge_type: charge.charge_type, value: charge.value, computed_cents: computed.round(2) }
      end

      total_charges = charges.sum { |c| c[:computed_cents] }

      {
        charges: charges,
        total_charges_cents: total_charges.round(2),
        net_proceeds_cents: (amount_cents - total_charges).round(2)
      }
    end
  end
end
