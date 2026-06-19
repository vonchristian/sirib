puts "\n=== Seeding Rich Demo Data ==="

if Membership::Member.count > 100
  puts "  → Skipped (already seeded #{Membership::Member.count} members)"
  return
end

coop = Cooperative.first
admin_user = User.find_by(email_address: "admin@example.com") || User.first
cash_account = Accounting::Account.find_by(account_code: "11110") || Accounting::Account.find_by(account_code: "11131")
savings_product = Treasury::SavingsProduct.find_by(name: "Regular Savings")
time_deposit_product = Treasury::TimeDepositProduct.first
equity_product = Equity::Product.find_by(product_code: "COMMON") || Equity::Product.first
loan_products = Lending::LoanProduct.all.to_a

if loan_products.empty?
  puts "  → Skipped (no loan products)"
  return
end

savings_liability_ledger = savings_product&.liability_ledger

# ── MEMBERS ─────────────────────────────────────────────────────────────

puts "  Creating 1000+ members..."

first_names = %w[
  Maria Jose Juan Ana Pedro Sofia Carlos Luz Ramon Isabel Antonio Carmen Victor Lorna Danilo Gloria
  Fernando Rosario Miguel Elena Josefa Manuel Dolores Ricardo Teresita Eduardo Corazon Roberto Purificacion
  Ernesto Milagros Benjamin Alicia Gerardo Norma Alberto Angelita Francisco Luzviminda Jaime Nenita
  Renato Marilou Mario Leticia Ronaldo Evelyn Dante Marilyn Felipe Maricel Leonardo Delia Gregorio
  Avelina Napoleon Edna Edgardo Imelda Ruben Zenaida Perfecto Bella Gregorio Visitacion
]
last_names = %w[
  Cruz Reyes Villanueva Mercado Dimagiba Santos Gonzales Yulo Macapagal Alcantara Samson Lopez Natividad
  Mendoza Fernandez Rivera Romero Ramos Castillo Angeles Bautista De Leon Del Rosario Torres Fernandez
  Ramos Aquino Valdez Garcia Dominguez Serrano Lazaro Cortez Mendoza Salvador Alvarez Pineda Araneta
  Tuazon David Mina Villamor Villanueva Enriquez Ignacio Jimenez Lara Magpantay Manalo De Guzman
]
middle_initials = %w[ A B C D E F G H I J K L M N O P Q R S T U V W X Z ]
birthdate_range = Date.new(1970, 1, 1)..Date.new(2000, 12, 31)

seen_names = Set.new
members = []
1000.times do
  fn = first_names.sample
  ln = last_names.sample
  key = "#{fn}#{ln}"
  next if seen_names.include?(key)
  seen_names << key

  m = Membership::Member.create!(
    first_name: fn,
    middle_name: middle_initials.sample,
    last_name: ln,
    gender: %w[male female].sample,
    civil_status: %w[single married married married divorced widowed].sample,
    mobile_number: "0917#{format('%07d', 1000 + members.size)}",
    birth_date: birthdate_range.to_a.sample,
    identifications_attributes: [
      { id_type: "BIR", id_number: "BIR-#{format('%09d', rand(10_000_000..99_999_999))}" }
    ]
  )
  members << m
end
puts "    → #{members.size} members created"

# ── SAVINGS ACCOUNTS ────────────────────────────────────────────────────

puts "  Creating savings accounts..."

if savings_product && savings_liability_ledger
  # Use a high starting code to avoid cross-ledger collisions
  global_max = Accounting::Account.maximum(:account_code).to_i
  next_code = [global_max, 100_000_000].max + 1
  code_counter = 0

  active_savers = members.sample(members.size * 6 / 10)
  active_savers.each_with_index do |member, i|
    acct_code = format('%05d', next_code + code_counter)
    code_counter += 1

    liability = Accounting::Account.create!(
      ledger: savings_liability_ledger,
      name: "#{savings_product.name} SV - #{member.first_name} #{member.last_name}",
      account_type: :liability,
      account_code: acct_code
    )

    account = Treasury::SavingsAccount.new(
      savings_product: savings_product,
      depositor: member,
      account_type: :personal,
      status: "active",
      account_number: format("SV-%07d", 2000 + i),
      opened_at: rand(30..730).days.ago
    )
    account.liability_account = liability
    account.save!

    # Keep deposits modest to avoid 4-byte RunningBalance.balance_cents overflow
    deposit = rand(500_00..50_000_00)
    Treasury::SavingsTransactionService.run!(
      savings_account: account,
      transaction_type: "deposit",
      amount_cents: deposit,
      cash_account: cash_account
    )
  rescue => e
    puts "    Warning: savings #{i} failed: #{e.message}"
  end

  # Closed (dormant) savings
  dormant_count = active_savers.size / 6
  dormant_count.times do |i|
    member = active_savers.sample
    next if Treasury::SavingsAccount.where(depositor: member).where.not(status: "active").exists?

    acct_code = format('%05d', next_code + code_counter)
    code_counter += 1

    liability = Accounting::Account.create!(
      ledger: savings_liability_ledger,
      name: "#{savings_product.name} SV - #{member.first_name} #{member.last_name}",
      account_type: :liability,
      account_code: acct_code
    )

    account = Treasury::SavingsAccount.new(
      savings_product: savings_product,
      depositor: member,
      account_type: :personal,
      status: "closed",
      account_number: format("SV-%07d", 3000 + i),
      opened_at: 400.days.ago,
      closed_at: 100.days.ago
    )
    account.liability_account = liability
    account.save!
  rescue => e
    # ignore duplicates
  end

  puts "    → #{Treasury::SavingsAccount.active.count} active, #{Treasury::SavingsAccount.where(status: "closed").count} closed"
else
  puts "    → Skipped (no savings product / ledger)"
end

# ── SHARE CAPITAL ───────────────────────────────────────────────────────

puts "  Creating share capital accounts..."

if equity_product
  min_shares = equity_product.minimum_required_shares
  price_cents = equity_product.price_per_share_cents

  full_members = members.sample(members.size * 3 / 10)
  partial_members = (members - full_members).sample(members.size / 10)

  full_members.each_with_index do |member, idx|
    shares = min_shares + rand(0..20)
    account = Equity::Account.create!(
      member: member,
      share_product: equity_product,
      account_number: format("EQ-%07d", 4000 + idx),
      opened_at: rand(100..500).days.ago,
      opened_by_id: admin_user.id,
      shares_owned: shares,
      paid_up_shares: shares
    )
    Equity::Transaction.create!(
      share_capital_account: account,
      transaction_type: :purchase,
      shares: shares,
      price_per_share_cents: price_cents,
      status: "completed",
      posted_at: account.opened_at,
      posted_by_id: admin_user.id
    )
  end

  partial_members.each_with_index do |member, idx|
    shares = [min_shares - 5, 1].max
    account = Equity::Account.create!(
      member: member,
      share_product: equity_product,
      account_number: format("EQ-%07d", 6000 + idx),
      opened_at: rand(30..200).days.ago,
      opened_by_id: admin_user.id,
      shares_owned: shares,
      paid_up_shares: shares
    )
    Equity::Transaction.create!(
      share_capital_account: account,
      transaction_type: :purchase,
      shares: shares,
      price_per_share_cents: price_cents,
      status: "completed",
      posted_at: account.opened_at,
      posted_by_id: admin_user.id
    )
  end

  puts "    → #{Equity::Account.count} accounts"
else
  puts "    → Skipped (no equity product)"
end

# ── LOANS ───────────────────────────────────────────────────────────────

puts "  Creating loans..."

paid_borrowers = members.sample(members.size / 10)
paid_borrowers.each do |member|
  product = loan_products.sample
  amount = rand(5_000_00..100_000_00)
  term = [3, 6, 12].sample
  interest = rand(1_000_00..amount / 4)

  app = Lending::LoanApplication.create!(
    cooperative: coop,
    member: member,
    loan_product: product,
    status: "disbursed",
    amount_cents: amount,
    amount_currency: "PHP",
    interest_rate: product.interest_rate,
    term_months: term
  )

  loan = Lending::Loan.create!(
    loan_application: app,
    member: member,
    loan_product: product,
    principal_cents: amount,
    interest_rate: product.interest_rate,
    interest_calculation: product.interest_calculation,
    term_months: term,
    status: "paid",
    outstanding_principal_cents: 0,
    disbursed_at: rand(90..365).days.ago
  )

  total = amount + interest
  Lending::LoanPayment.create!(
    loan: loan,
    amount_cents: total,
    principal_cents: amount,
    interest_cents: interest,
    penalty_cents: 0,
    payment_date: rand(loan.disbursed_at..Date.current)
  )
rescue => e
  # skip
end

active_borrowers = members.sample(members.size / 8)
active_borrowers.each do |member|
  product = loan_products.sample
  amount = rand(10_000_00..200_000_00)
  term = [3, 6, 12, 18, 24].sample
  remaining = amount * rand(3..9) / 10

  app = Lending::LoanApplication.create!(
    cooperative: coop,
    member: member,
    loan_product: product,
    status: "disbursed",
    amount_cents: amount,
    amount_currency: "PHP",
    interest_rate: product.interest_rate,
    term_months: term
  )

  Lending::Loan.create!(
    loan_application: app,
    member: member,
    loan_product: product,
    principal_cents: amount,
    interest_rate: product.interest_rate,
    interest_calculation: product.interest_calculation,
    term_months: term,
    status: "active",
    outstanding_principal_cents: remaining,
    disbursed_at: rand(30..180).days.ago
  )
rescue => e
  # skip
end

default_borrowers = members.sample(members.size / 10)
default_borrowers.each do |member|
  product = loan_products.sample
  amount = rand(5_000_00..80_000_00)
  term = [3, 6, 12].sample
  remaining = amount * rand(7..10) / 10

  app = Lending::LoanApplication.create!(
    cooperative: coop,
    member: member,
    loan_product: product,
    status: "disbursed",
    amount_cents: amount,
    amount_currency: "PHP",
    interest_rate: product.interest_rate,
    term_months: term
  )

  Lending::Loan.create!(
    loan_application: app,
    member: member,
    loan_product: product,
    principal_cents: amount,
    interest_rate: product.interest_rate,
    interest_calculation: product.interest_calculation,
    term_months: term,
    status: "defaulted",
    outstanding_principal_cents: remaining,
    disbursed_at: rand(180..400).days.ago
  )
rescue => e
  # skip
end

puts "    → #{Lending::Loan.where(status: 'paid').count} paid, #{Lending::Loan.active.count} active, #{Lending::Loan.where(status: 'defaulted').count} defaulted"

# ── TIME DEPOSITS ───────────────────────────────────────────────────────

puts "  Creating time deposits..."

if time_deposit_product
  td_near = members.sample(members.size / 20)
  td_fresh = members.sample(members.size / 20)

  td_near.each do |member|
    amount = rand(10_000_00..500_000_00)
    opened_days = time_deposit_product.term_in_days - rand(1..5)
    Treasury::TimeDeposit.create!(
      depositor: member,
      time_deposit_product: time_deposit_product,
      amount_cents: amount,
      amount_currency: "PHP",
      interest_rate: time_deposit_product.interest_rate,
      interest_earned_cents: (amount * time_deposit_product.interest_rate * opened_days / 365).round,
      interest_earned_currency: "PHP",
      status: "active",
      matured_on: opened_days.days.from_now.to_date,
      opened_at: opened_days.days.ago
    )
  end

  td_fresh.each do |member|
    amount = rand(10_000_00..300_000_00)
    opened_days = rand(1..14)
    Treasury::TimeDeposit.create!(
      depositor: member,
      time_deposit_product: time_deposit_product,
      amount_cents: amount,
      amount_currency: "PHP",
      interest_rate: time_deposit_product.interest_rate,
      interest_earned_cents: 0,
      interest_earned_currency: "PHP",
      status: "active",
      matured_on: (time_deposit_product.term_in_days - opened_days).days.from_now.to_date,
      opened_at: opened_days.days.ago
    )
  end

  puts "    → #{Treasury::TimeDeposit.active.count} active"
else
  puts "    → Skipped (no time deposit product)"
end

puts "=== Rich Demo Data Complete ==="
puts "  Members: #{Membership::Member.count}"
puts "  Loans: #{Lending::Loan.count}"
puts "  Savings Accounts: #{Treasury::SavingsAccount.count}"
puts "  Share Capital Accounts: #{Equity::Account.count}"
puts "  Time Deposits: #{Treasury::TimeDeposit.count}"
