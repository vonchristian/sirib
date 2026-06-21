puts "\n=== Seeding Complete Demo Data Per Cooperative ==="

def load_per_coop_seed(seed_name)
  load Rails.root.join("db/seeds/#{seed_name}.rb")
rescue LoadError, Errno::ENOENT
  Rails.logger.warn("Seed file db/seeds/#{seed_name}.rb not found, skipping")
end

Cooperative.active.order(:name).each_with_index do |coop, idx|
  puts "\n--- #{coop.name} ---"

  # ── 1. Chart of Accounts ───────────────────────────────────────────
  unless Accounting::Ledger.where(cooperative: coop).exists?
    load_per_coop_seed("chart_of_accounts")
  end

  # ── 2. Members ─────────────────────────────────────────────────────
  unless Membership::Member.where(cooperative: coop).exists?
    load_per_coop_seed("members")
  end

  # ── 3. Loan Products ───────────────────────────────────────────────
  unless Lending::LoanProduct.where(cooperative: coop).exists?
    load_per_coop_seed("loan_products")
  end

  # ── 4. Savings Products ────────────────────────────────────────────
  unless Treasury::SavingsProduct.where(cooperative: coop).exists?
    load_per_coop_seed("savings_products")
  end

  # ── 5. Sample Journal Entries ──────────────────────────────────────
  load_per_coop_seed("sample_entries")

  admin_user = User.find_by(cooperative: coop, role: :manager)
  admin_user_for_portal = admin_user || User.find_by(cooperative: coop, role: :manager)

  # ── 6. Portal Announcements ───────────────────────────────────────
  unless Portal::Announcement.exists?
    announcements = [
      { title: "Welcome to the Member Portal!",
        body: "We are excited to launch our new member portal. You can now view your savings, share capital, loan balances, and repayment schedules online anytime." },
      { title: "Quarterly Dividend Declaration",
        body: "The Board of Directors has approved a 3% dividend for all common shareholders for this quarter. Dividends will be credited to your share capital accounts by month end." },
      { title: "Annual General Meeting Announcement",
        body: "The Annual General Meeting will be held on December 15th at the cooperative hall. All members are encouraged to attend." }
    ]

    announcements.each_with_index do |attrs, i|
      Portal::Announcement.create!(
        cooperative_id: coop.id,
        title: attrs[:title],
        body: attrs[:body],
        status: "published",
        published_at: [1.day.ago, 1.week.ago, 2.weeks.ago][i],
        author_id: admin_user_for_portal&.id || User.where(cooperative: coop).first&.id
      )
    end
    puts "    #{announcements.size} portal announcements"
  end

  # ── 7. Management Structure ──────────────────────────────────────────
  unless Management::Branch.where(cooperative: coop).exists?
    load_per_coop_seed("management")
  end

  # ── 8. Equity Products ────────────────────────────────────────────
  unless Equity::Product.where(cooperative: coop).exists?
    equity_product = Equity::Product.create!(
      cooperative: coop,
      product_code: "COMMON",
      name: "Common Share Capital",
      description: "Standard common share capital",
      share_type: 0,
      status: "active",
      price_per_share_cents: 1000,
      minimum_required_shares: 10,
      minimum_initial_purchase: 10,
      equity_ledger_id: Accounting::Ledger.where(cooperative: coop).find_by(account_code: "31110")&.id
    )
    puts "    Created equity product: #{equity_product.name}"
  end

  # ── 9. Enable Portal for Members ─────────────────────────────────────
  members_with_portal = 0
  Membership::Member.where(cooperative: coop).find_each.with_index do |member, i|
    next if member.password_digest.present?
    member.update!(
      member_identifier: "MBR-#{coop.name.parameterize.upcase}-#{format('%04d', i + 1)}",
      password: "password123",
      portal_status: "active"
    )
    members_with_portal += 1
  end
  puts "    Portal enabled for #{members_with_portal} members" if members_with_portal > 0

  # ── 10. Create Sample Savings Accounts ───────────────────────────────
  savings_product = Treasury::SavingsProduct.where(cooperative: coop).first
  if savings_product && Treasury::SavingsAccount.where(cooperative: coop).count < 50
    members = Membership::Member.where(cooperative: coop).order(Arel.sql("RANDOM()")).limit(50).to_a
    members.each_with_index do |member, i|
      existing = Treasury::SavingsAccount.find_by(
        savings_product: savings_product,
        depositor_type: "Membership::Member",
        depositor_id: member.id
      )
      unless existing
        Treasury::SavingsAccount.create!(
          cooperative: coop,
          savings_product: savings_product,
          depositor: member,
          status: "active",
          opened_at: Time.current
        )
      end
    end
    puts "    Created #{Treasury::SavingsAccount.where(cooperative: coop).count} savings accounts"
  end

  # ── 11. Create Sample Equity Accounts ───────────────────────────────
  equity_prod = Equity::Product.where(cooperative: coop).first
  if equity_prod && Equity::Account.where(cooperative: coop).count < 30
    members = Membership::Member.where(cooperative: coop).order(Arel.sql("RANDOM()")).limit(30).to_a
    members.each_with_index do |member, i|
      existing = Equity::Account.find_by(
        member: member,
        share_product: equity_prod
      )
      unless existing
        Equity::Account.create!(
          cooperative: coop,
          member: member,
          share_product: equity_prod,
          status: "active",
          opened_at: Time.current,
          opened_by_id: admin_user.id,
          shares_owned: rand(10..100),
          paid_up_shares: rand(10..100)
        )
      end
    end
    puts "    Created #{Equity::Account.where(cooperative: coop).count} equity accounts"
  end

  # ── 12. Create Sample Loan Applications ────────────────────────────
  loan_products = Lending::LoanProduct.where(cooperative: coop).to_a
  if loan_products.any? && Lending::LoanApplication.where(cooperative: coop).count < 20
    members = Membership::Member.where(cooperative: coop).order(Arel.sql("RANDOM()")).limit(20).to_a
    members.each_with_index do |member, i|
      product = loan_products.sample
      status = ["draft", "submitted", "approved", "rejected"].sample
      app = Lending::LoanApplication.create!(
        cooperative_id: coop.id,
        member: member,
        loan_product: product,
        uuid: SecureRandom.uuid,
        status: status,
        amount_cents: rand(10_000_000..5_000_000_00),
        interest_rate: product.interest_rate,
        term_months: rand(6..60),
        submitted_at: status != "draft" ? Time.current : nil,
        approved_at: status == "approved" ? Time.current : nil
      )

      if status == "approved"
        Lending::Loan.create!(
          cooperative: coop,
          loan_application: app,
          member: member,
          loan_product: product,
          principal_cents: app.amount_cents,
          interest_rate: app.interest_rate,
          interest_calculation: product.interest_calculation,
          term_months: app.term_months,
          outstanding_principal_cents: app.amount_cents,
          status: "active",
          disbursed_at: Time.current
        )
      end
    end
    puts "    Created #{Lending::LoanApplication.where(cooperative: coop).count} loan applications"
  end

  # ── 13. Create Messaging Channels and Providers ─────────────────────
  unless Messaging::Channel.where(cooperative: coop).exists?
    sms = Messaging::Channel.create!(cooperative: coop, name: "SMS", enabled: true)
    email = Messaging::Channel.create!(cooperative: coop, name: "Email", enabled: true)
    push = Messaging::Channel.create!(cooperative: coop, name: "Push", enabled: true)

    Messaging::Provider.create!(
      cooperative: coop,
      channel: sms,
      name: "Twilio SMS",
      config: { api_key: "demo", from_number: "+1234567890" },
      enabled: true
    )
    Messaging::Provider.create!(
      cooperative: coop,
      channel: email,
      name: "SMTP Email",
      config: { smtp_host: "smtp.example.com", smtp_port: 587 },
      enabled: true
    )
    puts "    Created messaging channels and providers"
  end

  puts "    Seeded all demo data for #{coop.name}"
end
