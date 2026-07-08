puts "Seeding sample journal entries..."

accounts = Accounting::Account.all.index_by(&:account_code)

entries_data = [
  {
    description: "Initial member equity contribution",
    reference_number: "ENT-2025-0001",
    posted_at: Time.new(2025, 1, 15),
    debits: [ { account: accounts["11131"], amount: 10_000_000 } ],
    credits: [ { account: accounts["30130"], amount: 10_000_000 } ]
  },
  {
    description: "Loan disbursement to member - Juan Dela Cruz",
    reference_number: "ENT-2025-0002",
    posted_at: Time.new(2025, 3, 1),
    debits: [ { account: accounts["11210"], amount: 2_000_000 } ],
    credits: [ { account: accounts["11131"], amount: 2_000_000 } ]
  },
  {
    description: "Loan disbursement to member - Maria Santos",
    reference_number: "ENT-2025-0003",
    posted_at: Time.new(2025, 4, 1),
    debits: [ { account: accounts["11210"], amount: 1_000_000 } ],
    credits: [ { account: accounts["11133"], amount: 1_000_000 } ]
  },
  {
    description: "Loan collection - Juan Dela Cruz partial payment",
    reference_number: "ENT-2025-0004",
    posted_at: Time.new(2025, 5, 15),
    debits: [ { account: accounts["11133"], amount: 1_200_000 } ],
    credits: [ { account: accounts["11210"], amount: 1_200_000 } ]
  },
  {
    description: "Purchase of office furniture and fixtures",
    reference_number: "ENT-2025-0005",
    posted_at: Time.new(2025, 6, 1),
    debits: [ { account: accounts["14180"], amount: 500_000 } ],
    credits: [ { account: accounts["11131"], amount: 500_000 } ]
  },
  {
    description: "Member savings deposit",
    reference_number: "ENT-2025-0006",
    posted_at: Time.new(2025, 6, 15),
    debits: [ { account: accounts["11132"], amount: 300_000 } ],
    credits: [ { account: accounts["21110"], amount: 300_000 } ]
  }
]

entries_data.each do |attrs|
  unless Accounting::Entry.exists?(reference_number: attrs[:reference_number])
    Accounting::Entry.build(
      description: attrs[:description],
      reference_number: attrs[:reference_number],
      posted_at: attrs[:posted_at],
      debits: attrs[:debits],
      credits: attrs[:credits]
    ).save!
  end
end

puts "  → 6 sample journal entries created"
