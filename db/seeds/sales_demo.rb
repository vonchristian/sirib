# frozen_string_literal: true

puts "\n=== Sales Demo: Comprehensive Cooperative Data ==="

coop = Cooperative.first
admin = User.find_by(cooperative: coop, role: :manager) || User.find_by(cooperative: coop)
teller = User.find_by(cooperative: coop, role: :treasurer) || admin
cash_account = Accounting::Account.joins(:ledger).where(account_code: "11110", ledgers: { cooperative_id: coop.id }).first
cash_in_bank = Accounting::Account.joins(:ledger).where(account_code: "11131", ledgers: { cooperative_id: coop.id }).first
savings_product = Treasury::SavingsProduct.find_by(cooperative: coop, name: "Regular Savings")
savings_ledger = savings_product&.liability_ledger
loan_products = Lending::LoanProduct.where(cooperative: coop).to_a
equity_product = Equity::Product.find_by(cooperative: coop, product_code: "COMMON")
first_branch = Management::Branch.where(cooperative: coop).first

unless cash_account && cash_in_bank && savings_product && savings_ledger && loan_products.any? && equity_product
  puts "  ✗ Prerequisites missing. Run db:seed first."
  return
end

# ─── 1. MEMBERS ───────────────────────────────────────────────────────────

puts "\n  Creating 1000+ members..."

first_names = %w[
  Maria Jose Juan Ana Pedro Sofia Carlos Luz Ramon Isabel Antonio Carmen Victor Lorna Danilo Gloria
  Fernando Rosario Miguel Elena Josefa Manuel Dolores Ricardo Teresita Eduardo Corazon Roberto Purificacion
  Ernesto Milagros Benjamin Alicia Gerardo Norma Alberto Angelita Francisco Luzviminda Jaime Nenita
  Renato Marilou Mario Leticia Ronaldo Evelyn Dante Marilyn Felipe Maricel Leonardo Delia Gregorio
  Avelina Napoleon Edna Edgardo Imelda Ruben Zenaida Perfecto Bella Visitacion
]
last_names = %w[
  Cruz Reyes Villanueva Mercado Dimagiba Santos Gonzales Yulo Macapagal Alcantara Samson Lopez Natividad
  Mendoza Fernandez Rivera Romero Ramos Castillo Angeles Bautista De Leon Del Rosario Torres
  Aquino Valdez Garcia Dominguez Serrano Lazaro Cortez Salvador Alvarez Pineda Araneta
  Tuazon David Mina Villamor Enriquez Ignacio Jimenez Lara Magpantay Manalo De Guzman
  Dela Cruz Abad Simon Velasco Panganiban Marquez Tolentino Javier Vergara Villanueva
]
middle_initials = %w[ A B C D E F G H I J K L M N O P Q R S T U V W X Z ]
birthdate_range = Date.new(1970, 1, 1)..Date.new(2000, 12, 31)

seen_names = Set.new
members = []
existing_count = Membership::Member.where(cooperative: coop).count

if existing_count < 100
  (1000 - existing_count).times do |i|
    fn = first_names.sample
    ln = last_names.sample
    key = "#{fn}#{ln}"
    next if seen_names.include?(key)
    seen_names << key

    m = Membership::Member.create!(
      cooperative: coop,
      first_name: fn,
      middle_name: middle_initials.sample,
      last_name: ln,
      gender: %w[male female].sample,
      civil_status: %w[single married married married divorced widowed].sample,
      mobile_number: "0917#{format('%07d', 1000 + members.size)}",
      birth_date: birthdate_range.to_a.sample,
      member_identifier: "MBR-#{coop.name.parameterize.upcase}-#{format('%04d', existing_count + members.size + 1)}",
      identifications_attributes: [ {
        cooperative: coop,
        id_type: "BIR",
        id_number: format("%03d-%03d-%03d", rand(100..999), rand(100..999), rand(100..999))
      } ]
    )
    members << m
  end
  puts "    → #{members.size} new members created"
else
  puts "    → #{existing_count} members already exist"
end

members = Membership::Member.where(cooperative: coop).to_a
puts "    → #{members.size} total members"

# ─── 2. SAVINGS ACCOUNTS (70%) ────────────────────────────────────────────

puts "\n  Creating savings accounts..."

existing_savers = Treasury::SavingsAccount.where(cooperative: coop).count
savers_needed = (members.size * 0.7).to_i - existing_savers

if savers_needed > 0
  max_code = Accounting::Account.where(cooperative: coop).maximum(:account_code).to_i
  code_counter = 0

  eligible = members.reject { |m| Treasury::SavingsAccount.exists?(depositor_id: m.id) }
  created_count = 0

  puts "    debug: coop_id=#{coop.id} savings_product=#{savings_product&.id} ledger=#{savings_ledger&.id} max_code=#{max_code} eligible=#{eligible.size}"

  eligible.sample(savers_needed).each_with_index do |member, _i|
    code_counter += 1
    acct_code = format("%05d", max_code + code_counter)

    begin
      liability = Accounting::Account.create!(
        ledger: savings_ledger,
        name: "SA - #{member.first_name} #{member.last_name}",
        account_type: :liability,
        account_code: acct_code,
        cooperative: coop
      )
    rescue => e
      if e.respond_to?(:record)
        puts "    [acct fail] #{e.message} errors=#{e.record.errors.full_messages.join(', ')}"
      else
        puts "    [acct fail] #{e.message}"
      end
      next
    end

    initial_balance = rand(500_00..50_000_00)

    begin
      account = Treasury::SavingsAccount.create!(
        cooperative: coop,
        savings_product: savings_product,
        depositor: member,
        account_type: :personal,
        status: "active",
        opened_at: rand(60..730).days.ago,
        liability_account: liability
      )
    rescue => e
      if e.respond_to?(:record)
        puts "    [sa fail] #{e.message} errors=#{e.record.errors.full_messages.join(', ')}"
      else
        puts "    [sa fail] #{e.message}"
      end
      next
    end

    begin
      Treasury::SavingsTransaction.create!(
        cooperative: coop,
        savings_account: account,
        transaction_type: :deposit,
        amount_cents: initial_balance,
        amount_currency: "PHP",
        cash_account: cash_account,
        status: "completed",
        posted_at: account.opened_at
      )
    rescue => e
      info = e.respond_to?(:record) ? e.record.errors.full_messages.join(', ') : ''
      puts "    [txn-create fail] #{e.message} #{info}"
      next
    end

    begin
      Accounting::PostEntryService.run!(
        description: "Initial deposit - #{member.first_name} #{member.last_name}",
        reference_number: "DEP-#{account.account_number}-INIT",
        posted_at: account.opened_at,
        cooperative: coop,
        debits: [ { account: cash_account, amount: initial_balance } ],
        credits: [ { account: liability, amount: initial_balance } ]
      )
    rescue => e
      puts "    [post fail] #{e.message}"
      next
    end
    created_count += 1
  end

  puts "    → Created #{created_count} new savings accounts"
end

puts "    → #{Treasury::SavingsAccount.where(cooperative: coop).count} total savings accounts"

savings_accounts = Treasury::SavingsAccount.where(cooperative: coop).active.to_a

# ─── 3. SHARE CAPITAL (30%) ───────────────────────────────────────────────

puts "\n  Creating share capital accounts..."

existing_equity = Equity::Account.where(cooperative: coop).count
equity_needed = (members.size * 0.3).to_i - existing_equity

if equity_needed > 0
  eligible = members.reject { |m| Equity::Account.exists?(member: m) }
  eligible.sample(equity_needed).each_with_index do |member, i|
    shares = equity_product.minimum_required_shares + rand(0..25)
    account = Equity::Account.create!(
      cooperative: coop,
      member: member,
      share_product: equity_product,
      account_number: format("EQ-%07d", 4000 + i),
      opened_at: rand(30..500).days.ago,
      opened_by_id: admin.id,
      shares_owned: shares,
      paid_up_shares: shares,
      status: "active"
    )
    Equity::Transaction.create!(
      cooperative: coop,
      share_capital_account: account,
      transaction_type: :purchase,
      shares: shares,
      price_per_share_cents: equity_product.price_per_share_cents,
      total_amount_cents: shares * equity_product.price_per_share_cents,
      status: "completed",
      posted_at: account.opened_at,
      posted_by_id: admin.id
    )
  end
  puts "    → Created #{equity_needed} new equity accounts"
end

puts "    → #{Equity::Account.where(cooperative: coop).count} total equity accounts"

# ─── 4. LOANS (20%) ──────────────────────────────────────────────────────

puts "\n  Creating loans..."

existing_loans = Lending::Loan.where(cooperative: coop).count
total_loans = (members.size * 0.2).to_i
loans_needed = total_loans - existing_loans

if loans_needed > 0
  borrowers = members.reject { |m| Lending::Loan.exists?(member: m) }

  # Paid loans (1/3 of new)
  paid_count = (loans_needed / 3).to_i
  borrowers.sample(paid_count).each do |member|
    product = loan_products.sample
    amount = rand(10_000_00..150_000_00)
    term = [ 3, 6, 12 ].sample
    interest = rand(1_000_00..amount / 5)
    disbursed_at = rand(90..365).days.ago

    app = Lending::LoanApplication.create!(
      cooperative: coop, member: member, loan_product: product,
      status: "disbursed", amount_cents: amount, amount_currency: "PHP",
      interest_rate: product.interest_rate, term_months: term,
      reference_number: "LA-#{coop.name.parameterize}-PAID-#{format('%04d', rand(9999))}"
    )

    loan = Lending::Loan.create!(
      cooperative: coop, loan_application: app, member: member, loan_product: product,
      principal_cents: amount, interest_rate: product.interest_rate,
      interest_calculation: product.interest_calculation, term_months: term,
      status: "paid", outstanding_principal_cents: 0, disbursed_at: disbursed_at,
      reference_number: "LN-PAID-#{format('%04d', rand(9999))}"
    )

    Lending::LoanPayment.create!(
      loan: loan, amount_cents: amount + interest, principal_cents: amount,
      interest_cents: interest, penalty_cents: 0,
      payment_date: rand(disbursed_at..Date.current)
    )
  rescue => e
    # skip
  end

  # Active loans (1/3 of new)
  active_count = (loans_needed / 3).to_i
  borrowers.sample(active_count).each do |member|
    product = loan_products.sample
    amount = rand(20_000_00..300_000_00)
    term = [ 6, 12, 18, 24 ].sample
    remaining = (amount * rand(4..9) / 10.0).round
    disbursed_at = rand(15..120).days.ago

    app = Lending::LoanApplication.create!(
      cooperative: coop, member: member, loan_product: product,
      status: "disbursed", amount_cents: amount, amount_currency: "PHP",
      interest_rate: product.interest_rate, term_months: term,
      reference_number: "LA-#{coop.name.parameterize}-ACT-#{format('%04d', rand(9999))}"
    )

    Lending::Loan.create!(
      cooperative: coop, loan_application: app, member: member, loan_product: product,
      principal_cents: amount, interest_rate: product.interest_rate,
      interest_calculation: product.interest_calculation, term_months: term,
      status: "active", outstanding_principal_cents: remaining,
      disbursed_at: disbursed_at,
      reference_number: "LN-ACT-#{format('%04d', rand(9999))}"
    )
  rescue => e
    # skip
  end

  # Defaulted loans (rest)
  default_count = loans_needed - paid_count - active_count
  borrowers.sample(default_count).each do |member|
    product = loan_products.sample
    amount = rand(5_000_00..100_000_00)
    term = [ 3, 6, 12 ].sample
    remaining = (amount * rand(7..10) / 10.0).round
    disbursed_at = rand(180..400).days.ago

    app = Lending::LoanApplication.create!(
      cooperative: coop, member: member, loan_product: product,
      status: "disbursed", amount_cents: amount, amount_currency: "PHP",
      interest_rate: product.interest_rate, term_months: term,
      reference_number: "LA-#{coop.name.parameterize}-DFT-#{format('%04d', rand(9999))}"
    )

    Lending::Loan.create!(
      cooperative: coop, loan_application: app, member: member, loan_product: product,
      principal_cents: amount, interest_rate: product.interest_rate,
      interest_calculation: product.interest_calculation, term_months: term,
      status: "defaulted", outstanding_principal_cents: remaining,
      disbursed_at: disbursed_at,
      reference_number: "LN-DFT-#{format('%04d', rand(9999))}"
    )
  rescue => e
    # skip
  end

  puts "    → #{Lending::Loan.where(cooperative: coop).count} total loans"
end

active_loans = Lending::Loan.where(cooperative: coop, status: "active").to_a

puts "    → #{Lending::Loan.where(status: 'paid').count} paid, #{active_loans.size} active, #{Lending::Loan.where(status: 'defaulted').count} defaulted"

# ─── 5. DAILY TRANSACTIONS (30 days) ──────────────────────────────────────

puts "\n  Generating 30 days of daily transactions..."
puts "    Debug: #{savings_accounts.size} savings accounts, #{active_loans.size} active loans, cash_account=#{cash_account&.account_code}"

total_deposits = 0
total_withdrawals = 0
total_payments = 0

(1..30).reverse_each do |day_offset|
  date = Date.current - day_offset.days
  day_label = date.strftime("%b %d")
  print "    Day #{day_offset}/30 (#{day_label}): "

  posted_at = date.to_time + (9..16).to_a.sample.hours + rand(0..59).minutes

  # ── Daily deposits (15-25 random savers) ────────────────────────────
  deposit_count = rand(15..25)
  savers = savings_accounts.sample(deposit_count)
  day_deposits = 0

  savers.each do |sa|
    amount = rand(200_00..15_000_00)

    Treasury::SavingsTransaction.create!(
      cooperative: coop,
      savings_account: sa,
      transaction_type: :deposit,
      amount_cents: amount,
      amount_currency: "PHP",
      cash_account: cash_account,
      status: "completed",
      posted_at: posted_at
    )

    Accounting::PostEntryService.run!(
      description: "Savings deposit - #{sa.account_number}",
      reference_number: "SD-#{date.strftime('%Y%m%d')}-#{format('%04d', rand(9999))}",
      posted_at: posted_at,
      cooperative: coop,
      debits: [ { account: cash_account, amount: amount } ],
      credits: [ { account: sa.liability_account, amount: amount } ]
    )
    day_deposits += 1
  rescue => e
    puts "      [deposit fail] #{e.message}"
  end

  # ── Daily withdrawals (5-12 random savers) ──────────────────────────
  withdraw_count = rand(5..12)
  withdraw_savers = savings_accounts.sample(withdraw_count)
  day_withdrawals = 0

  withdraw_savers.each do |sa|
    amount = rand(100_00..8_000_00)

    Treasury::SavingsTransaction.create!(
      cooperative: coop,
      savings_account: sa,
      transaction_type: :withdraw,
      amount_cents: amount,
      amount_currency: "PHP",
      cash_account: cash_account,
      status: "completed",
      posted_at: posted_at + 1.hour
    )

    Accounting::PostEntryService.run!(
      description: "Savings withdrawal - #{sa.account_number}",
      reference_number: "SW-#{date.strftime('%Y%m%d')}-#{format('%04d', rand(9999))}",
      posted_at: posted_at + 1.hour,
      cooperative: coop,
      debits: [ { account: sa.liability_account, amount: amount } ],
      credits: [ { account: cash_account, amount: amount } ]
    )
    day_withdrawals += 1
  rescue => e
    puts "      [withdraw fail] #{e.message}"
  end

  # ── Daily loan payments (3-8 active loans) ──────────────────────────
  payment_count = [ rand(3..8), active_loans.size ].min
  payers = active_loans.sample(payment_count)
  day_payments = 0

  payers.each do |loan|
    principal_payment = [ loan.outstanding_principal_cents, rand(1_000_00..15_000_00) ].min
    next if principal_payment <= 0

    interest = (principal_payment * (loan.interest_rate / 100.0 / 12)).round
    total_payment = principal_payment + interest

    Lending::LoanPayment.create!(
      loan: loan,
      amount_cents: total_payment,
      principal_cents: principal_payment,
      interest_cents: interest,
      penalty_cents: 0,
      payment_date: date
    )

    loan.update!(outstanding_principal_cents: loan.outstanding_principal_cents - principal_payment)

    interest_income_acct = Accounting::Account.joins(:ledger).where(account_code: "40110", ledgers: { cooperative_id: coop.id }).first
    loan_receivable_acct = Accounting::Account.joins(:ledger).where(account_code: "11210", ledgers: { cooperative_id: coop.id }).first

    if interest_income_acct && loan_receivable_acct
      Accounting::PostEntryService.run!(
        description: "Loan payment - #{loan.member.first_name} #{loan.member.last_name}",
        reference_number: "LP-#{date.strftime('%Y%m%d')}-#{format('%04d', rand(9999))}",
        posted_at: posted_at + 2.hours,
        cooperative: coop,
        debits: [ { account: cash_account, amount: total_payment } ],
        credits: [
          { account: loan_receivable_acct, amount: principal_payment },
          { account: interest_income_acct, amount: interest }
        ]
      )
    end
    day_payments += 1
  rescue => e
    puts "      [payment fail] #{e.message}"
  end

  total_deposits += day_deposits
  total_withdrawals += day_withdrawals
  total_payments += day_payments
  puts "#{day_deposits} deposits, #{day_withdrawals} withdrawals, #{day_payments} loan payments"
end

puts "\n  Transactions generated:"
puts "    → #{total_deposits} deposits"
puts "    → #{total_withdrawals} withdrawals"
puts "    → #{total_payments} loan payments"
puts "    → #{Treasury::SavingsTransaction.count} total savings transactions"
puts "    → #{Accounting::Entry.count} total journal entries"

# ─── 6. MONTHLY INTEREST ACCRUAL ──────────────────────────────────────────

puts "\n  Creating month-end accrual entries..."

interest_income_acct = Accounting::Account.joins(:ledger).where(account_code: "40110", ledgers: { cooperative_id: coop.id }).first
loan_receivable_acct = Accounting::Account.joins(:ledger).where(account_code: "11210", ledgers: { cooperative_id: coop.id }).first

if interest_income_acct && loan_receivable_acct
  active_loans.each do |loan|
    monthly_interest = (loan.outstanding_principal_cents * (loan.interest_rate / 100.0 / 12)).round
    next if monthly_interest <= 0

    Accounting::PostEntryService.run!(
      description: "Monthly interest accrual - #{loan.member.first_name} #{loan.member.last_name}",
      reference_number: "INTR-ACCRUAL-#{format('%04d', rand(9999))}",
      posted_at: 1.day.ago.beginning_of_day,
      cooperative: coop,
      debits: [ { account: loan_receivable_acct, amount: monthly_interest } ],
      credits: [ { account: interest_income_acct, amount: monthly_interest } ]
    )
  rescue => e
    # skip
  end
  puts "    → Interest accrued for active loans"
end

# ─── 7. CASH SESSIONS ────────────────────────────────────────────────────

puts "\n  Creating cash sessions..."

unless Treasury::CashSession.where(cooperative: coop).exists?
  Treasury::CashSession.create!(
    cooperative: coop,
    user: teller,
    opened_at: 30.days.ago.beginning_of_day + 8.hours,
    beginning_balance_cents: 500_000_00,
    status: "closed"
  )

  (1..29).reverse_each do |day_offset|
    date = (Date.current - day_offset.days).to_time + 8.hours
    Treasury::CashSession.create!(
      cooperative: coop,
      user: teller,
      opened_at: date,
      closed_at: date + 8.hours,
      beginning_balance_cents: 300_000_00 + rand(0..200_000_00),
      ending_balance_cents: 250_000_00 + rand(0..300_000_00),
      status: "closed"
    )
  rescue => e
    # skip
  end

  Treasury::CashSession.create!(
    cooperative: coop,
    user: teller,
    opened_at: Time.current.beginning_of_day + 8.hours,
    beginning_balance_cents: 400_000_00,
    status: "open"
  )

  puts "    → #{Treasury::CashSession.where(cooperative: coop).count} cash sessions created"
end

# ─── 8. PORTAL ACCESS ─────────────────────────────────────────────────────

puts "\n  Enabling portal for members..."

portal_count = 0
members.sample(300).each do |member|
  next if member.password_digest.present?

  member.update!(
    password: "password123",
    portal_status: "active"
  )
  portal_count += 1
end
puts "    → Portal enabled for #{portal_count} more members"

puts "\n  ✅ Sales demo data complete!"
puts "  Members: #{Membership::Member.where(cooperative: coop).count}"
puts "  Savings Accounts: #{Treasury::SavingsAccount.where(cooperative: coop).count}"
puts "  Savings Transactions: #{Treasury::SavingsTransaction.count}"
puts "  Loans: #{Lending::Loan.where(cooperative: coop).count}"
puts "  Loan Payments: #{Lending::LoanPayment.count}"
puts "  Equity Accounts: #{Equity::Account.where(cooperative: coop).count}"
puts "  Journal Entries: #{Accounting::Entry.count}"
puts "  Cash Sessions: #{Treasury::CashSession.where(cooperative: coop).count}"
