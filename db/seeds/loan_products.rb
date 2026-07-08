charges_by_product = {
  "Regular Salary Loan"    => [ { name: "Service Fee",       charge_type: "percentage", value: 2.0  },
                               { name: "Application Fee",   charge_type: "fixed",      value: 200 } ],
  "Emergency Loan"         => [ { name: "Service Fee",       charge_type: "percentage", value: 3.0  },
                               { name: "Processing Fee",    charge_type: "fixed",      value: 150 } ],
  "Educational Loan"       => [ { name: "Service Fee",       charge_type: "percentage", value: 1.5  },
                               { name: "Application Fee",   charge_type: "fixed",      value: 250 } ],
  "Housing Loan"           => [ { name: "Service Fee",       charge_type: "percentage", value: 1.0  },
                               { name: "Appraisal Fee",     charge_type: "fixed",      value: 1000 },
                               { name: "Notarial Fee",      charge_type: "fixed",      value: 500 } ],
  "Livelihood Loan"        => [ { name: "Service Fee",       charge_type: "percentage", value: 2.0  },
                               { name: "Application Fee",   charge_type: "fixed",      value: 300 } ],
  "Motorcycle Loan"        => [ { name: "Service Fee",       charge_type: "percentage", value: 2.5  },
                               { name: "Application Fee",   charge_type: "fixed",      value: 500 } ],
  "Agri Loan"              => [ { name: "Service Fee",       charge_type: "percentage", value: 1.0  },
                               { name: "Inspection Fee",    charge_type: "fixed",      value: 350 } ],
  "Petty Cash Loan"        => [ { name: "Service Fee",       charge_type: "percentage", value: 5.0  } ],
  "Provident Loan"         => [ { name: "Service Fee",       charge_type: "percentage", value: 1.0 } ],
  "Special Loan for Women" => [ { name: "Service Fee",       charge_type: "percentage", value: 0.5 },
                               { name: "Application Fee",   charge_type: "fixed",      value: 100 } ]
}

products = [
  { name: "Regular Salary Loan",         interest_rate: 1.5,  interest_calculation: "declining_balance", max_term_months: 24, requires_collateral: false },
  { name: "Emergency Loan",              interest_rate: 2.0,  interest_calculation: "declining_balance", max_term_months: 6,  requires_collateral: false },
  { name: "Educational Loan",            interest_rate: 1.0,  interest_calculation: "straight_line",     max_term_months: 36, requires_collateral: false },
  { name: "Housing Loan",                interest_rate: 0.75, interest_calculation: "declining_balance", max_term_months: 120, requires_collateral: true  },
  { name: "Livelihood Loan",             interest_rate: 1.25, interest_calculation: "declining_balance", max_term_months: 18, requires_collateral: true  },
  { name: "Motorcycle Loan",             interest_rate: 1.5,  interest_calculation: "declining_balance", max_term_months: 36, requires_collateral: true  },
  { name: "Agri Loan",                   interest_rate: 1.0,  interest_calculation: "straight_line",     max_term_months: 12, requires_collateral: true  },
  { name: "Petty Cash Loan",             interest_rate: 2.5,  interest_calculation: "straight_line",     max_term_months: 3,  requires_collateral: false },
  { name: "Provident Loan",              interest_rate: 1.0,  interest_calculation: "declining_balance", max_term_months: 12, requires_collateral: false },
  { name: "Special Loan for Women",      interest_rate: 0.5,  interest_calculation: "straight_line",     max_term_months: 12, requires_collateral: false }
]

products.each do |attrs|
  product = Lending::LoanProduct.find_or_create_by!(name: attrs[:name], cooperative: @coop) do |p|
    p.assign_attributes(attrs)
  end

  next unless (product_charges = charges_by_product[product.name])

  product_charges.each do |charge_attrs|
    product.loan_charges.find_or_create_by!(name: charge_attrs[:name], cooperative: @coop) do |c|
      c.assign_attributes(charge_attrs)
    end
  end
end

puts "Seeded #{Lending::LoanProduct.count} loan products"
