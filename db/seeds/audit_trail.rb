def run_year_long_audit_trail
  puts "\n=== Generating Year-Long Teller Audit Trail ==="

  Cooperative.active.order(:name).each do |coop|
    puts "\n--- #{coop.name} ---"
    seed_year_teller_audit(coop)
  end
end

def seed_year_teller_audit(coop)
  if Accounting::Entry.where(cooperative: coop).where("posted_at >= ?", 1.year.ago).count > 0 &&
     Accounting::AmountLine.joins(:entry).where(cooperative_id: coop.id).where("amount_lines.created_at >= ?", 1.year.ago).count > 1000
    puts "  Already seeded, skipping"
    return
  end

  teller = User.where(cooperative: coop).first
  unless teller
    puts "  No users found, skipping"
    return
  end

  a = {}
  %w[11110 11131 11133 11210 21110 30130 40110 40120 40210 60010 60070 60080 60090].each do |code|
    a[code] = Accounting::Account.joins(:ledger).where(account_code: code, ledgers: { cooperative_id: coop.id }).first
  end

  required = %w[11110 11133 11210 21110 30130]
  missing = required.reject { |c| a[c] }
  if missing.any?
    puts "  Missing accounts #{missing.join(', ')}, skipping"
    return
  end

  members = Membership::Member.where(cooperative: coop).to_a
  if members.empty?
    puts "  No members found, skipping"
    return
  end

  start_date = Date.new(2025, 7, 1)
  end_date   = Date.new(2026, 6, 30)
  date_range = start_date..end_date
  holidays   = %w[2025-12-25 2025-12-31 2026-01-01 2026-04-09 2026-05-01].to_set

  rng           = Random.new(42)
  counter       = (Accounting::Entry.maximum(:id) || 0) + 1
  total_created = 0
  entries_buf   = []
  lines_buf     = []
  batch_size    = 50

  date_range.each do |date|
    next if date.sunday? || holidays.include?(date.to_s)

    hour_base = 8 + rng.rand(9)

    (2 + rng.rand(4)).times do
      member = members[rng.rand(members.size)]
      amount = (rng.rand(80) + 1) * 500
      t      = Time.new(date.year, date.month, date.day, hour_base, rng.rand(60), 0)
      ref    = "DEP-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
      entries_buf << new_entry(coop, teller, ref, "Savings deposit — #{member.first_name} #{member.last_name}", t, "manual_entry", "source_treasury")
      lines_buf << new_line(coop, a["11110"].id, "debit",  amount, t)
      lines_buf << new_line(coop, a["21110"].id, "credit", amount, t)
      counter += 1
    end

    (1 + rng.rand(3)).times do
      member = members[rng.rand(members.size)]
      amount = (rng.rand(40) + 1) * 500
      t      = Time.new(date.year, date.month, date.day, hour_base, rng.rand(60), 0)
      ref    = "WDL-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
      entries_buf << new_entry(coop, teller, ref, "Savings withdrawal — #{member.first_name} #{member.last_name}", t, "manual_entry", "source_treasury")
      lines_buf << new_line(coop, a["21110"].id, "debit",  amount, t)
      lines_buf << new_line(coop, a["11110"].id, "credit", amount, t)
      counter += 1
    end

    if (date.tuesday? || date.thursday?) && a["11210"] && a["11133"]
      member = members[rng.rand(members.size)]
      amount = (rng.rand(100) + 5) * 1000
      t      = Time.new(date.year, date.month, date.day, 9 + rng.rand(4), rng.rand(60), 0)
      ref    = "DSB-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
      entries_buf << new_entry(coop, teller, ref, "Loan disbursement — #{member.first_name} #{member.last_name}", t, "system_entry", "source_loans")
      lines_buf << new_line(coop, a["11210"].id, "debit",  amount, t)
      lines_buf << new_line(coop, a["11133"].id, "credit", amount, t)
      counter += 1
    end

    loan_repay_day = date.end_of_month.mday - 5
    if (date.day >= 18 && date.day <= 25) && date.day == loan_repay_day
      3.times do
        member    = members[rng.rand(members.size)]
        principal = (rng.rand(40) + 2) * 500
        interest  = (rng.rand(10) + 1) * 500
        total     = principal + interest
        t         = Time.new(date.year, date.month, date.day, 10 + rng.rand(5), rng.rand(60), 0)
        ref       = "REP-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
        entries_buf << new_entry(coop, teller, ref, "Loan repayment — #{member.first_name} #{member.last_name}", t, "manual_entry", "source_loans")
        lines_buf << new_line(coop, a["11133"].id, "debit",  total,     t)
        lines_buf << new_line(coop, a["11210"].id, "credit", principal, t)
        lines_buf << new_line(coop, a["40110"].id, "credit", interest,  t)
        counter += 1
      end
    end

    is_last_bday = date == date_range.reject { |d| d.sunday? || holidays.include?(d.to_s) }
                                  .select { |d| d >= date.beginning_of_month && d <= date.end_of_month }
                                  .last
    if is_last_bday && a["30130"]
      4.times do
        member = members[rng.rand(members.size)]
        shares = (rng.rand(20) + 1) * 5
        amount = shares * 100_00
        t      = Time.new(date.year, date.month, date.day, 14, rng.rand(60), 0)
        ref    = "SCP-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
        entries_buf << new_entry(coop, teller, ref, "Share capital purchase — #{member.first_name} #{member.last_name} (#{shares} shares)", t, "manual_entry", "source_equity")
        lines_buf << new_line(coop, a["11133"].id, "debit",  amount, t)
        lines_buf << new_line(coop, a["30130"].id, "credit", amount, t)
        counter += 1
      end
    end

    if date.mday == 10 || date.mday == 25
      2.times do
        member = members[rng.rand(members.size)]
        amount = (rng.rand(10) + 1) * 100_00
        t      = Time.new(date.year, date.month, date.day, 11, rng.rand(60), 0)
        ref    = "SVC-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
        entries_buf << new_entry(coop, teller, ref, "Service fee — #{member.first_name} #{member.last_name}", t, "fees_entry", "source_manual")
        lines_buf << new_line(coop, a["11110"].id, "debit",  amount, t)
        lines_buf << new_line(coop, a["40120"].id, "credit", amount, t)
        counter += 1
      end
    end

    is_last_monday = date.monday? && date.day >= 22
    if is_last_monday && a["60010"] && a["60090"] && a["60070"] && a["60080"]
      sal_t = Time.new(date.year, date.month, date.day, 8, 0, 0)
      [
        [ "SAL", a["60010"], "Monthly salaries and wages", 180_000_00 ],
        [ "RNT", a["60090"], "Monthly office rent",         45_000_00 ],
        [ "UTL", a["60070"], "Electricity and water",       12_000_00 ],
        [ "TEL", a["60080"], "Telephone and internet",        6_500_00 ]
      ].each do |prefix, exp_acct, desc, amt|
        ref = "#{prefix}-#{date.strftime('%Y%m%d')}-#{counter.to_s.rjust(5, '0')}"
        entries_buf << new_entry(coop, teller, ref, desc, sal_t, "system_entry", "source_manual")
        lines_buf << new_line(coop, exp_acct.id,    "debit",  amt, sal_t)
        lines_buf << new_line(coop, a["11133"].id,  "credit", amt, sal_t)
        counter += 1
      end
    end

    if entries_buf.size >= batch_size
      total_created += do_insert(coop, entries_buf, lines_buf)
      print "."
      entries_buf.clear
      lines_buf.clear
    end
  end

  if entries_buf.any?
    total_created += do_insert(coop, entries_buf, lines_buf)
    entries_buf.clear
    lines_buf.clear
  end

  puts "\n  → #{total_created} journal entries created for Jul 2025 – Jun 2026"
  compute_month_end_balances(coop, a)
rescue => e
  puts "  Warning: Audit seed failed: #{e.class}: #{e.message}"
  puts e.backtrace.first(3).join("\n")
end

def new_entry(coop, teller, ref, desc, t, type, source)
  { cooperative_id: coop.id, reference_number: ref, description: desc,
    posted_at: t, status: "posted", entry_type: type,
    source_module: source, created_by_id: teller.id }
end

def new_line(coop, account_id, amount_type, amount_cents, t)
  { cooperative_id: coop.id, account_id: account_id, amount_type: amount_type,
    amount_cents: amount_cents, created_at: t, updated_at: t }
end

def do_insert(coop, entries, lines)
  return 0 if entries.empty?

  result = Accounting::Entry.insert_all!(entries, returning: :id)
  entry_ids = result.rows.flatten

  lines_with_eids = lines.each_with_index.filter_map do |line, i|
    eid = entry_ids[i / 2]
    eid ? line.merge(entry_id: eid) : nil
  end

  Accounting::AmountLine.insert_all!(lines_with_eids)
  entries.size
rescue => e
  puts "\n  Batch insert error: #{e.message}"
  entries.size
end

def compute_month_end_balances(coop, account_map)
  month_ends = (0..11).map { |i| Date.new(2026, 6, 1).prev_month(i).end_of_month }.reverse
  rb_batch   = []
  rb_id      = (Accounting::RunningBalance.maximum(:id) || 0) + 1

  account_map.values.each do |acct|
    month_ends.each do |me|
      next if me < Date.new(2025, 7, 1)
      bal = acct.balance(to_date: me)
      rb_batch << { id: rb_id, account_id: acct.id, ledger_id: acct.ledger_id,
                    balance_cents: bal.cents, as_of_date: me,
                    cooperative_id: coop.id,
                    created_at: Time.current, updated_at: Time.current }
      rb_id += 1
    end
  end

  Accounting::RunningBalance.insert_all!(rb_batch) rescue nil
  puts "  → #{rb_batch.size} month-end running balance records created"
end
