CDA_ACCOUNT_TYPES = {
  asset:    ->(code) { code.start_with?("1") },
  liability: ->(code) { code.start_with?("2") },
  equity:   ->(code) { code.start_with?("3") },
  revenue:  ->(code) { code.start_with?("4") },
  expense:  ->(code) { %w[5 6].include?(code[0]) }
}.freeze

CONTRA_PREFIXES = [
  "Allowance for",
  "Accumulated Depreciation",
  "Unearned",
  "Discounts on Loans Payable",
  "Sales Returns",
  "Sales Discounts",
  "Treasury Shares Capital",
  "Unrealized Gross Margin"
].freeze

def account_type_for(code)
  CDA_ACCOUNT_TYPES.each { |type, matcher| return type.to_s if matcher.call(code) }
  "expense"
end

def contra?(name)
  CONTRA_PREFIXES.any? { |prefix| name.start_with?(prefix) }
end

LEDGERS = {
  "111" => { name: "Cash and Cash Equivalents", type: "asset" },
  "1113" => { name: "Cash in Bank", type: "asset", parent: "111", code: "11130" },
  "112" => { name: "Loans and Receivables", type: "asset" },
  "114" => { name: "Financial Assets", type: "asset" },
  "115" => { name: "Inventories", type: "asset" },
  "116" => { name: "Biological Assets — Current", type: "asset" },
  "120" => { name: "Other Current Assets", type: "asset" },
  "131" => { name: "Financial Assets — Long Term", type: "asset" },
  "132" => { name: "Investment in Subsidiaries", type: "asset" },
  "133" => { name: "Investment in Associates", type: "asset" },
  "134" => { name: "Investment in Joint Ventures", type: "asset" },
  "135" => { name: "Investment Property", type: "asset" },
  "140" => { name: "Property, Plant and Equipment", type: "asset" },
  "150" => { name: "Biological Assets — Non-Current", type: "asset" },
  "160" => { name: "Intangible Assets", type: "asset" },
  "170" => { name: "Other Non-Current Assets", type: "asset" },
  "211" => { name: "Deposit Liabilities", type: "liability" },
  "212" => { name: "Trade and Other Payables", type: "liability" },
  "213" => { name: "Accrued Expenses", type: "liability" },
  "214" => { name: "Other Current Liabilities", type: "liability" },
  "220" => { name: "Non-Current Liabilities", type: "liability" },
  "230" => { name: "Other Non-Current Liabilities", type: "liability" },
  "301" => { name: "Members' Equity", type: "equity" },
  "306" => { name: "Donations and Grants", type: "equity" },
  "307" => { name: "Statutory Funds", type: "equity" },
  "308" => { name: "Revaluation Surplus", type: "equity" },
  "401" => { name: "Income from Credit Operations", type: "revenue" },
  "402" => { name: "Income from Service Operations", type: "revenue" },
  "403" => { name: "Income from Marketing/Consumers/Production", type: "revenue" },
  "404" => { name: "Other Income", type: "revenue" },
  "510" => { name: "Cost of Goods Sold", type: "expense" },
  "600" => { name: "Operating Expenses", type: "expense" },
  "700" => { name: "Other Income and Expenses", type: "expense" }
}.freeze

ACCOUNTS = [
  { code: "11110", name: "Cash on Hand",                  ledger: "111" },
  { code: "11120", name: "Checks & Other Cash Items",      ledger: "111" },
  { code: "11131", name: "PNB Savings Account",            ledger: "1113" },
  { code: "11132", name: "PNB Checking Account",           ledger: "1113" },
  { code: "11133", name: "LandBank Account 001",           ledger: "1113" },
  { code: "11134", name: "LandBank Account 002",           ledger: "1113" },
  { code: "11140", name: "Cash in Cooperative Federation", ledger: "111" },
  { code: "11150", name: "Petty Cash Fund",                ledger: "111" },
  { code: "11160", name: "Revolving Fund",                 ledger: "111" },
  { code: "11170", name: "Change Fund",                    ledger: "111" },
  { code: "11180", name: "ATM Fund",                       ledger: "111" },

  { code: "11210", name: "Loans Receivable — Current",         ledger: "112" },
  { code: "11220", name: "Loans Receivable — Past Due",        ledger: "112" },
  { code: "11230", name: "Loans Receivable — Restructured",    ledger: "112" },
  { code: "11240", name: "Loans Receivable — Loans in Litigation", ledger: "112" },
  { code: "11241", name: "Unearned Interests and Discounts",          ledger: "112" },
  { code: "11242", name: "Allowance for Probable Losses — Loans",    ledger: "112" },
  { code: "11250", name: "Accounts Receivable Trade — Current",      ledger: "112" },
  { code: "11260", name: "Accounts Receivable Trade — Past Due",     ledger: "112" },
  { code: "11270", name: "Accounts Receivable Trade — Restructured", ledger: "112" },
  { code: "11280", name: "Accounts Receivable Trade — in Litigation", ledger: "112" },
  { code: "11281", name: "Allowance for Probable Losses — Accounts Receivable Trade", ledger: "112" },
  { code: "11290", name: "Installment Receivables — Current",        ledger: "112" },
  { code: "11300", name: "Installment Receivables — Past Due",       ledger: "112" },
  { code: "11310", name: "Installment Receivables — Restructured",   ledger: "112" },
  { code: "11320", name: "Installment Receivables — in Litigation",  ledger: "112" },
  { code: "11321", name: "Allowance for Probable Losses — Installment Receivables", ledger: "112" },
  { code: "11322", name: "Unrealized Gross Margin",                  ledger: "112" },
  { code: "11330", name: "Sales Contract Receivable",                ledger: "112" },
  { code: "11331", name: "Allowance for Probable Losses — Sales Contract Receivables", ledger: "112" },
  { code: "11340", name: "Accounts Receivable — Non-Trade",          ledger: "112" },
  { code: "11341", name: "Allowance for Probable Losses — Accounts Receivable Non-Trade", ledger: "112" },
  { code: "11350", name: "Advances to Officers, Employees and Members", ledger: "112" },
  { code: "11360", name: "Due from Accountable Officers, Employees and Members", ledger: "112" },
  { code: "11370", name: "Finance Lease Receivable",                 ledger: "112" },
  { code: "11371", name: "Allowance for Impairment — Finance Lease Receivable", ledger: "112" },
  { code: "11380", name: "Other Current Receivables",                ledger: "112" },

  { code: "11410", name: "Financial Asset at Fair Value Through Profit or Loss", ledger: "114" },
  { code: "11420", name: "Financial Asset at Cost",                            ledger: "114" },

  { code: "11510", name: "Merchandise Inventory",                    ledger: "115" },
  { code: "11520", name: "Repossessed Inventories",                  ledger: "115" },
  { code: "11530", name: "Spare Parts/Materials & Other Goods Inventory", ledger: "115" },
  { code: "11540", name: "Raw Materials Inventory",                  ledger: "115" },
  { code: "11550", name: "Work in Process Inventory",                ledger: "115" },
  { code: "11560", name: "Finished Goods Inventory",                 ledger: "115" },
  { code: "11570", name: "Inventory Agricultural Produce",           ledger: "115" },
  { code: "11580", name: "Equipment for Lease Inventory",            ledger: "115" },
  { code: "11590", name: "Allowance for Impairment — Inventory",     ledger: "115" },

  { code: "11610", name: "Biological Assets — Current",              ledger: "116" },

  { code: "12110", name: "Input Tax",                                ledger: "120" },
  { code: "12120", name: "Creditable VAT",                           ledger: "120" },
  { code: "12130", name: "Creditable Withholding Tax",               ledger: "120" },
  { code: "12140", name: "Deposit to Suppliers",                     ledger: "120" },
  { code: "12150", name: "Unused Supplies",                          ledger: "120" },
  { code: "12160", name: "Assets Acquired in Settlement of Loans/Accounts", ledger: "120" },
  { code: "12161", name: "Accumulated Depreciation — Assets Acquired in Settlement", ledger: "120" },
  { code: "12170", name: "Prepaid Expenses",                         ledger: "120" },
  { code: "12200", name: "Other Current Assets",                     ledger: "120" },

  { code: "13110", name: "Financial Asset at Cost — Long Term",         ledger: "131" },
  { code: "13120", name: "Financial Asset at Amortized Cost — Long Term", ledger: "131" },

  { code: "13200", name: "Investment in Subsidiaries", ledger: "132" },
  { code: "13300", name: "Investment in Associates",   ledger: "133" },
  { code: "13400", name: "Investment in Joint Ventures", ledger: "134" },

  { code: "13510", name: "Investment Property — Land",         ledger: "135" },
  { code: "13520", name: "Investment Property — Building",     ledger: "135" },
  { code: "13521", name: "Accumulated Depreciation — Investment Property — Building", ledger: "135" },
  { code: "13530", name: "Real Properties Acquired (RPA)",     ledger: "135" },
  { code: "13610", name: "Accumulated Depreciation — RPA",     ledger: "135" },

  { code: "14110", name: "Land",                     ledger: "140" },
  { code: "14120", name: "Land Improvements",        ledger: "140" },
  { code: "14121", name: "Accumulated Depreciation — Land Improvements", ledger: "140" },
  { code: "14130", name: "Building and Improvements", ledger: "140" },
  { code: "14131", name: "Accumulated Depreciation — Building and Improvements", ledger: "140" },
  { code: "14140", name: "Building on Leased/Usufruct Land", ledger: "140" },
  { code: "14141", name: "Accumulated Depreciation — Building on Leased/Usufruct Land", ledger: "140" },
  { code: "14150", name: "Utility Plant",                               ledger: "140" },
  { code: "14151", name: "Accumulated Depreciation — Utility Plant",    ledger: "140" },
  { code: "14160", name: "Property, Plant & Equipment — Under Finance Lease", ledger: "140" },
  { code: "14161", name: "Accumulated Depreciation — PPE Under Finance Lease", ledger: "140" },
  { code: "14170", name: "Construction in Progress",                    ledger: "140" },
  { code: "14180", name: "Furniture, Fixtures & Equipment (FFE)",       ledger: "140" },
  { code: "14181", name: "Accumulated Depreciation — FFE",              ledger: "140" },
  { code: "14190", name: "Machineries, Tools and Equipment",            ledger: "140" },
  { code: "14191", name: "Accumulated Depreciation — Machineries, Tools and Equipment", ledger: "140" },
  { code: "14200", name: "Kitchen, Canteen & Catering Equipment/Utensils", ledger: "140" },
  { code: "14201", name: "Accumulated Depreciation — Kitchen, Canteen & Catering Equipment", ledger: "140" },
  { code: "14210", name: "Transportation Equipment",                    ledger: "140" },
  { code: "14211", name: "Accumulated Depreciation — Transportation Equipment", ledger: "140" },
  { code: "14220", name: "Linens and Uniforms",                         ledger: "140" },
  { code: "14221", name: "Accumulated Depreciation — Linens and Uniforms", ledger: "140" },
  { code: "14230", name: "Nursery/Greenhouses",                         ledger: "140" },
  { code: "14231", name: "Accumulated Depreciation — Nursery/Greenhouse", ledger: "140" },
  { code: "14240", name: "Leasehold Rights & Improvements",             ledger: "140" },
  { code: "14290", name: "Other Property, Plant and Equipment",         ledger: "140" },

  { code: "15100", name: "Biological Assets — Animals", ledger: "150" },
  { code: "15110", name: "Accumulated Depreciation — Biological Assets — Animals", ledger: "150" },
  { code: "15200", name: "Biological Assets — Plants",  ledger: "150" },
  { code: "15210", name: "Accumulated Depreciation — Biological Assets — Plants", ledger: "150" },

  { code: "16100", name: "Franchise",      ledger: "160" },
  { code: "16200", name: "Franchise Cost", ledger: "160" },
  { code: "16300", name: "Copyright",      ledger: "160" },
  { code: "16400", name: "Patent",         ledger: "160" },

  { code: "17100", name: "Computerization Cost",               ledger: "170" },
  { code: "17200", name: "Other Funds and Deposits",           ledger: "170" },
  { code: "17300", name: "Due from Head Office/Branch/Satellites", ledger: "170" },
  { code: "17400", name: "Deposit on Returnable Containers",   ledger: "170" },
  { code: "17900", name: "Miscellaneous Assets",               ledger: "170" },

  { code: "21110", name: "Saving Deposits", ledger: "211" },
  { code: "21120", name: "Time Deposits",   ledger: "211" },

  { code: "21210", name: "Accounts Payable — Trade",         ledger: "212" },
  { code: "21220", name: "Accounts Payable — Non-Trade",     ledger: "212" },
  { code: "21230", name: "Loans Payable — Current",          ledger: "212" },
  { code: "21240", name: "Finance Lease Payable — Current",  ledger: "212" },
  { code: "21250", name: "Due to Deployed Members",          ledger: "212" },
  { code: "21260", name: "Cash Bond Payable",                ledger: "212" },
  { code: "21290", name: "Other Payables",                   ledger: "212" },

  { code: "21310", name: "Due to Regulatory Agencies",              ledger: "213" },
  { code: "21320", name: "SSS/ECC/Philhealth/Pag-IBIG Premium Contributions Payable", ledger: "213" },
  { code: "21330", name: "SSS/Pag-IBIG Loans Payable",              ledger: "213" },
  { code: "21340", name: "Withholding Tax Payable",                  ledger: "213" },
  { code: "21350", name: "Output Tax",                               ledger: "213" },
  { code: "21360", name: "VAT Payable",                              ledger: "213" },
  { code: "21370", name: "Income Tax Payable",                       ledger: "213" },
  { code: "21390", name: "Other Accrued Expenses",                   ledger: "213" },

  { code: "21410", name: "Deposit from Customers",              ledger: "214" },
  { code: "21420", name: "Advances from Customers",             ledger: "214" },
  { code: "21430", name: "School Program Support Fund Payable", ledger: "214" },
  { code: "21440", name: "Interest on Share Capital Payable",   ledger: "214" },
  { code: "21450", name: "Patronage Refund Payable",            ledger: "214" },
  { code: "21460", name: "Due to Union/Federation (CETF)",      ledger: "214" },
  { code: "21490", name: "Other Current Liabilities",           ledger: "214" },

  { code: "22100", name: "Loans Payable — Long Term",           ledger: "220" },
  { code: "22200", name: "Discounts on Loans Payable",          ledger: "220" },
  { code: "22300", name: "Revolving Capital Payable",           ledger: "220" },
  { code: "22400", name: "Retirement Payable",                  ledger: "220" },
  { code: "22500", name: "Finance Lease Payable — Long Term",   ledger: "220" },

  { code: "23110", name: "Project Subsidy Fund",                ledger: "230" },
  { code: "23120", name: "Members' Benefit and Other Funds Payable", ledger: "230" },
  { code: "23130", name: "Due to Head Office/Branch/Satellite", ledger: "230" },
  { code: "23140", name: "CSF Guarantee Fund",                  ledger: "230" },
  { code: "23190", name: "Other Non-Current Liabilities",       ledger: "230" },

  { code: "30110", name: "Subscribed Share Capital — Common",       ledger: "301" },
  { code: "30120", name: "Subscription Receivable — Common",        ledger: "301" },
  { code: "30130", name: "Paid-up Share Capital — Common",          ledger: "301" },
  { code: "30131", name: "Treasury Shares Capital — Common",        ledger: "301" },
  { code: "30210", name: "Subscribed Share Capital — Preferred",    ledger: "301" },
  { code: "30220", name: "Subscription Receivable — Preferred",     ledger: "301" },
  { code: "30230", name: "Paid-up Share Capital — Preferred",       ledger: "301" },
  { code: "30231", name: "Treasury Shares Capital — Preferred",     ledger: "301" },
  { code: "30300", name: "Deposit for Share Capital Subscription",  ledger: "301" },
  { code: "30400", name: "Undivided Net Surplus",                   ledger: "301" },
  { code: "30500", name: "Net Loss",                                ledger: "301" },

  { code: "30600", name: "Donations/Grants", ledger: "306" },

  { code: "30710", name: "Reserve Fund",                  ledger: "307" },
  { code: "30720", name: "Cooperative Education & Training Fund", ledger: "307" },
  { code: "30730", name: "Community Development Fund",     ledger: "307" },
  { code: "30740", name: "Optional Fund",                 ledger: "307" },

  { code: "30800", name: "Revaluation Surplus", ledger: "308" },

  { code: "40110", name: "Interest Income from Loans",                ledger: "401" },
  { code: "40120", name: "Service Fees",                               ledger: "401" },
  { code: "40130", name: "Filing Fees",                                ledger: "401" },
  { code: "40140", name: "Fines, Penalties, Surcharges",               ledger: "401" },

  { code: "40210", name: "Service Income",                             ledger: "402" },
  { code: "40220", name: "Interest Income from Lease Agreement",       ledger: "402" },

  { code: "40310", name: "Sales",                                      ledger: "403" },
  { code: "40320", name: "Installment Sales",                          ledger: "403" },
  { code: "40330", name: "Sales Returns & Allowances",                 ledger: "403" },
  { code: "40340", name: "Sales Discounts",                            ledger: "403" },

  { code: "40410", name: "Income/Interest from Investments/Deposits",  ledger: "404" },
  { code: "40420", name: "Membership Fee",                             ledger: "404" },
  { code: "40430", name: "Commission Income",                          ledger: "404" },
  { code: "40440", name: "Realized Gross Margin",                      ledger: "404" },
  { code: "40450", name: "Miscellaneous Income",                       ledger: "404" },

  { code: "51110", name: "Purchases",                                  ledger: "510" },
  { code: "51120", name: "Purchase Returns & Allowances",              ledger: "510" },
  { code: "51130", name: "Purchase Discounts",                         ledger: "510" },
  { code: "51140", name: "Freight In",                                 ledger: "510" },
  { code: "51150", name: "Cost of Goods Sold — Service",               ledger: "510" },

  { code: "60010", name: "Salaries and Wages",                         ledger: "600" },
  { code: "60020", name: "Directors' Per Diem and Allowances",         ledger: "600" },
  { code: "60030", name: "SSS/Philhealth/Pag-IBIG Contributions",      ledger: "600" },
  { code: "60040", name: "Employee Benefits",                          ledger: "600" },
  { code: "60050", name: "Training and Seminars",                      ledger: "600" },
  { code: "60060", name: "Office Supplies",                            ledger: "600" },
  { code: "60070", name: "Light and Water",                            ledger: "600" },
  { code: "60080", name: "Telephone and Internet",                     ledger: "600" },
  { code: "60090", name: "Rent Expense",                               ledger: "600" },
  { code: "60100", name: "Repairs and Maintenance",                    ledger: "600" },
  { code: "60110", name: "Depreciation Expense",                       ledger: "600" },
  { code: "60120", name: "Amortization Expense",                       ledger: "600" },
  { code: "60130", name: "Insurance Expense",                          ledger: "600" },
  { code: "60140", name: "Taxes and Licenses",                         ledger: "600" },
  { code: "60150", name: "Professional Fees",                          ledger: "600" },
  { code: "60160", name: "Transportation and Travel",                  ledger: "600" },
  { code: "60170", name: "Representation Expense",                     ledger: "600" },
  { code: "60180", name: "Advertising and Promotions",                 ledger: "600" },
  { code: "60190", name: "Communication Expense",                      ledger: "600" },
  { code: "60200", name: "Security Expense",                           ledger: "600" },
  { code: "60210", name: "Janitorial Expense",                         ledger: "600" },
  { code: "60220", name: "Bank Charges",                               ledger: "600" },
  { code: "60230", name: "Interest Expense",                           ledger: "600" },
  { code: "60240", name: "Bad Debts Expense",                          ledger: "600" },
  { code: "60250", name: "Miscellaneous Expense",                      ledger: "600" },
  { code: "60260", name: "Cooperative Education and Training Expense", ledger: "600" },
  { code: "60270", name: "Community Development Expense",              ledger: "600" },
  { code: "60280", name: "Optional Fund Expense",                      ledger: "600" },
  { code: "60290", name: "Members' Benefit Expense",                   ledger: "600" },
  { code: "60300", name: "Documentation and Filing Expense",           ledger: "600" },
  { code: "60310", name: "Fuel and Oil Expense",                       ledger: "600" },
  { code: "60320", name: "Cost of Member Services",                    ledger: "600" },
  { code: "60330", name: "Dues and Subscriptions",                     ledger: "600" },
  { code: "60340", name: "Supervision and Examination Fee",            ledger: "600" },
  { code: "69990", name: "Other Operating Expenses",                   ledger: "600" },

  { code: "70100", name: "Finance Income",        ledger: "700" },
  { code: "70200", name: "Finance Cost",          ledger: "700" },
  { code: "70300", name: "Gain on Sale of Assets", ledger: "700" },
  { code: "70400", name: "Loss on Sale of Assets", ledger: "700" },
  { code: "70500", name: "Extraordinary Gains",   ledger: "700" },
  { code: "70600", name: "Extraordinary Losses",  ledger: "700" }
].freeze

puts "Seeding chart of accounts..."

ledger_cache = {}

LEDGERS.each do |code_prefix, attrs|
  account_code = attrs[:code] || "#{code_prefix}00"
  ledger = Accounting::Ledger.find_or_create_by!(account_code: account_code, cooperative: @coop) do |l|
    l.name = attrs[:name]
    l.account_type = attrs[:type]
  end
  ledger_cache[code_prefix] = ledger
end

LEDGERS.each do |code_prefix, attrs|
  next unless attrs[:parent]

  parent = ledger_cache[attrs[:parent]]
  child = ledger_cache[code_prefix]
  child.update!(parent: parent) unless child.parent == parent
end

ACCOUNTS.each do |attrs|
  ledger = ledger_cache[attrs[:ledger]]
  acct_type = account_type_for(attrs[:code])
  is_contra = contra?(attrs[:name])

  Accounting::Account.find_or_create_by!(account_code: attrs[:code], cooperative: @coop) do |a|
    a.name = attrs[:name]
    a.ledger = ledger
    a.account_type = acct_type
    a.contra = is_contra
  end
end

puts "  → #{LEDGERS.size} ledgers created for #{@coop.name}"
puts "  → #{ACCOUNTS.size} accounts created for #{@coop.name}"
