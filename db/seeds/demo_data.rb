puts "\n=== Seeding Demo Data Per Cooperative ==="

def load_per_tenant_seed(seed_name)
  load Rails.root.join("db/seeds/#{seed_name}.rb")
rescue LoadError, Errno::ENOENT
  Rails.logger.warn("Seed file db/seeds/#{seed_name}.rb not found, skipping")
end

Cooperative.active.provisioned.order(:name).each_with_index do |coop, idx|
  puts "\n--- #{coop.name} ---"

  Tenant::SchemaManager.within_schema(coop.schema_name) do
    # ── 1. Sample journal entries ──────────────────────────────────────
    load_per_tenant_seed("sample_entries")

    # ── 2. Members ─────────────────────────────────────────────────────
    unless Membership::Member.exists?
      load_per_tenant_seed("members")
    end

    admin_user = User.find_by(cooperative: coop, role: :manager)

    # ── 3. Equity products & accounts ──────────────────────────────────
    unless Equity::Product.exists?
      common = Equity::Product.create!(
        product_code: "COMMON",
        name: "Common Share",
        description: "Regular common share with voting rights",
        share_type: :common,
        price_per_share_cents: 1_000_00,
        minimum_required_shares: 1,
        maximum_allowed_shares: 1000,
        minimum_initial_purchase: 1,
        voting_rights: true,
        dividend_eligible: true,
        redeemable: true
      )

      Equity::Product.create!(
        product_code: "PREFERRED",
        name: "Preferred Share",
        description: "Preferred share with dividend priority",
        share_type: :preferred,
        price_per_share_cents: 5_000_00,
        minimum_required_shares: 1,
        maximum_allowed_shares: 500,
        minimum_initial_purchase: 1,
        voting_rights: false,
        dividend_eligible: true,
        redeemable: true
      )
    end

    members = Membership::Member.limit(3).to_a
    common_product = Equity::Product.find_by(product_code: "COMMON")

    members.each_with_index do |member, i|
      next unless common_product

      account = Equity::Account.find_or_create_by!(member: member, share_product: common_product) do |a|
        a.status = "active"
        a.opened_by_id = admin_user&.id || 0
        a.shares_owned = (i + 1) * 10
        a.paid_up_shares = (i + 1) * 10
      end

      next if Equity::Transaction.exists?(share_capital_account: account)

      Equity::Transaction.create!(
        share_capital_account: account,
        transaction_type: :purchase,
        reference_number: "EQ-#{format('%s-%04d', coop.subdomain, i + 1)}",
        shares: (i + 1) * 10,
        price_per_share_cents: 1_000_00,
        total_amount_cents: (i + 1) * 10 * 1_000_00,
        status: :completed,
        posted_at: 30.days.ago,
        posted_by_id: admin_user&.id || 0
      )
    end

    # ── 4. Loan applications & loans ───────────────────────────────────
    loan_products = Lending::LoanProduct.where(name: [ "Regular Salary Loan", "Emergency Loan", "Educational Loan" ]).to_a

    if loan_products.any? && Lending::LoanApplication.count < 3
      members.each_with_index do |member, i|
        loan_product = loan_products[i % loan_products.size]
        prefix = coop.subdomain.underscore

        app = Lending::LoanApplication.find_or_create_by!(reference_number: "LA-#{prefix}-#{format('%04d', i + 1)}") do |a|
          a.cooperative = coop
          a.member = member
          a.loan_product = loan_product
          a.uuid = SecureRandom.uuid
          a.status = "approved"
          a.current_step = 5
          a.amount_cents = (i + 1) * 50_000_00
          a.interest_rate = loan_product.interest_rate
          a.term_months = loan_product.max_term_months
          a.submitted_at = 45.days.ago
          a.approved_at = 40.days.ago
        end

        next if Lending::Loan.exists?(loan_application_id: app.id)

        loan = Lending::Loan.create!(
          loan_application: app,
          member: member,
          loan_product: loan_product,
          principal_cents: app.amount_cents,
          interest_rate: app.interest_rate,
          interest_calculation: loan_product.interest_calculation,
          term_months: app.term_months,
          outstanding_principal_cents: app.amount_cents,
          status: :active,
          disbursed_at: 38.days.ago,
          reference_number: "LN-#{prefix}-#{format('%04d', i + 1)}"
        )

        cash_account = Accounting::Account.find_by(account_code: "11131")
        loan_receivable = Accounting::Account.find_by(account_code: "11210")

        if cash_account && loan_receivable
          Accounting::PostEntryService.run!(
            description: "Loan disbursement - #{member.first_name} #{member.last_name}",
            reference_number: "DSB-#{prefix}-#{format('%04d', i + 1)}",
            posted_at: 38.days.ago,
            debits: [ { account: loan_receivable, amount: app.amount_cents } ],
            credits: [ { account: cash_account, amount: app.amount_cents } ]
          )
        end
      end
    end

    # ── 5. Savings accounts ────────────────────────────────────────────
    regular_savings = Treasury::SavingsProduct.find_by(name: "Regular Savings")
    if regular_savings
      members.each_with_index do |member, i|
        next if Treasury::SavingsAccount.exists?(depositor_id: member.id, depositor_type: member.class.model_name.name)

        account = Treasury::SavingsAccount.create!(
          savings_product: regular_savings,
          depositor: member,
          account_type: :personal,
          status: "active"
        )

        next unless account.liability_account

        cash_account = Accounting::Account.find_by(account_code: "11131")
        prefix = coop.subdomain.underscore

        if cash_account
          Accounting::PostEntryService.run!(
            description: "Initial savings deposit - #{member.first_name} #{member.last_name}",
            reference_number: "SVP-#{prefix}-#{format('%04d', i + 1)}",
            posted_at: 25.days.ago,
            debits: [ { account: cash_account, amount: (i + 1) * 5_000_00 } ],
            credits: [ { account: account.liability_account, amount: (i + 1) * 5_000_00 } ]
          )
        end

        Treasury::SavingsTransaction.create!(
          savings_account: account,
          transaction_type: :deposit,
          amount_cents: (i + 1) * 5_000_00,
          cash_account: cash_account,
          reference_number: "STX-#{prefix}-#{format('%04d', i + 1)}",
          status: :completed,
          posted_at: 25.days.ago
        )
      end
    end

    # ── 6. Time deposits ───────────────────────────────────────────────
    td_product = Treasury::TimeDepositProduct.find_or_create_by!(name: "Regular Time Deposit") do |p|
      p.description = "Standard 30-day time deposit with competitive interest"
      p.minimum_deposit_cents = 5_000_00
      p.interest_rate = 0.035
      p.term_in_days = 30
      p.status = "active"
    end

    if td_product
      members.each_with_index do |member, i|
        next if Treasury::TimeDeposit.exists?(depositor_id: member.id, depositor_type: member.class.model_name.name)

        Treasury::TimeDeposit.create!(
          depositor: member,
          time_deposit_product: td_product,
          amount_cents: (i + 1) * 100_000_00,
          interest_rate: td_product.interest_rate,
          matured_on: 60.days.from_now,
          interest_earned_cents: 0,
          status: :active,
          opened_at: 30.days.ago
        )
      end
    end

    # ── 7. Additional journal entries ──────────────────────────────────
    cash_on_hand = Accounting::Account.find_by(account_code: "11110")
    interest_income = Accounting::Account.find_by(account_code: "40110")
    salaries_expense = Accounting::Account.find_by(account_code: "60010")
    rent_expense = Accounting::Account.find_by(account_code: "60090")
    service_fees = Accounting::Account.find_by(account_code: "40120")
    bank_acct = Accounting::Account.find_by(account_code: "11131")
    bank_charges = Accounting::Account.find_by(account_code: "60220")
    prefix = coop.subdomain.underscore

    additional_entries = [
      { ref: "ENT-#{prefix}-001", desc: "Interest income from loans - monthly accrual",
        posted: 15.days.ago,
        debits: [ { account: Accounting::Account.find_by(account_code: "11210"), amount: 75_000_00 } ],
        credits: [ { account: interest_income, amount: 75_000_00 } ] },
      { ref: "ENT-#{prefix}-002", desc: "Monthly salaries and wages",
        posted: 10.days.ago,
        debits: [ { account: salaries_expense, amount: 250_000_00 } ],
        credits: [ { account: bank_acct, amount: 250_000_00 } ] },
      { ref: "ENT-#{prefix}-003", desc: "Monthly rent payment",
        posted: 5.days.ago,
        debits: [ { account: rent_expense, amount: 50_000_00 } ],
        credits: [ { account: bank_acct, amount: 50_000_00 } ] },
      { ref: "ENT-#{prefix}-004", desc: "Service fees collected from loan processing",
        posted: 3.days.ago,
        debits: [ { account: cash_on_hand, amount: 12_000_00 } ],
        credits: [ { account: service_fees, amount: 12_000_00 } ] },
      { ref: "ENT-#{prefix}-005", desc: "Bank service charges",
        posted: 1.day.ago,
        debits: [ { account: bank_charges, amount: 2_500_00 } ],
        credits: [ { account: bank_acct, amount: 2_500_00 } ] }
    ]

    additional_entries.each do |entry_attrs|
      next if Accounting::Entry.exists?(reference_number: entry_attrs[:ref])

      Accounting::PostEntryService.run!(
        description: entry_attrs[:desc],
        reference_number: entry_attrs[:ref],
        posted_at: entry_attrs[:posted],
        debits: entry_attrs[:debits],
        credits: entry_attrs[:credits]
      )
    end

    # ── 8. Branch performance snapshots ────────────────────────────────
    branches = Management::Branch.all.to_a
    branch_perf_templates = [
      { loan_portfolio_cents: 8_500_000_00, savings_balance_cents: 3_200_000_00, delinquency_rate: 2.1,
        collection_efficiency: 95.3, cash_flow_position_cents: 4_100_000_00, estimated_profitability_cents: 1_200_000_00, total_members: 45 },
      { loan_portfolio_cents: 5_200_000_00, savings_balance_cents: 2_800_000_00, delinquency_rate: 3.8,
        collection_efficiency: 91.7, cash_flow_position_cents: 2_300_000_00, estimated_profitability_cents: 780_000_00, total_members: 32 },
      { loan_portfolio_cents: 3_800_000_00, savings_balance_cents: 1_900_000_00, delinquency_rate: 5.2,
        collection_efficiency: 88.4, cash_flow_position_cents: 1_600_000_00, estimated_profitability_cents: 520_000_00, total_members: 28 }
    ]

    branches.each_with_index do |branch, i|
      template = branch_perf_templates[i % branch_perf_templates.size]
      variation = 1.0 + ((idx + 1) * 0.05)

      [ Date.current, 7.days.ago.to_date ].each do |snap_date|
        Management::BranchPerformanceSnapshot.find_or_create_by!(branch: branch, snapshot_date: snap_date) do |s|
          s.metrics = {
            loan_portfolio_cents: (template[:loan_portfolio_cents] * variation).to_i,
            savings_balance_cents: (template[:savings_balance_cents] * variation).to_i,
            delinquency_rate: template[:delinquency_rate],
            collection_efficiency: template[:collection_efficiency],
            cash_flow_position_cents: (template[:cash_flow_position_cents] * variation).to_i,
            estimated_profitability_cents: (template[:estimated_profitability_cents] * variation).to_i,
            total_members: template[:total_members] + idx
          }
        end
      end
    end

    # ── 9. Role assignments for per-coop users ─────────────────────────
    coop_users = User.where(cooperative: coop).to_a
    branch = branches.first

    role_codes = {
      manager: "general_manager",
      loan_officer: "loan_officer",
      treasurer: "teller",
      accountant: "accountant"
    }

    coop_users.each do |user|
      role_code = role_codes[user.role.to_sym]
      next unless role_code

      role = Management::Role.find_by(code: role_code)
      next unless role

      Management::RoleAssignment.find_or_create_by!(user: user, role: role, branch: branch)
    end

    # ── 10. Risk indicators ────────────────────────────────────────────
    risk_data = [
      { type: "credit_risk_delinquency", value: 3.5, threshold: 5.0, status: :elevated, branch: nil },
      { type: "liquidity_ratio", value: 0.35, threshold: 0.2, status: :normal, branch: nil },
      { type: "portfolio_at_risk", value: 4.2, threshold: 5.0, status: :elevated, branch: nil }
    ]

    branches.each do |br|
      risk_data << { type: "credit_risk_delinquency", value: 2.1 + (idx * 0.5), threshold: 5.0, status: :normal, branch: br }
      risk_data << { type: "portfolio_at_risk", value: 2.8 + (idx * 0.5), threshold: 5.0, status: :elevated, branch: br }
    end

    risk_data.each do |data|
      Management::RiskIndicator.find_or_create_by!(
        indicator_type: data[:type],
        branch: data[:branch],
        as_of_date: Date.current
      ) do |r|
        r.value = data[:value]
        r.threshold = data[:threshold]
        r.status = data[:status]
      end
    end

    # ── 11. System health snapshots ────────────────────────────────────
    health_metrics = [
      { name: "transaction_throughput", value: 142.5, unit: "tps" },
      { name: "queue_depth", value: 8, unit: "jobs" },
      { name: "posting_latency_ms", value: 234.0, unit: "ms" },
      { name: "error_rate", value: 0.5, unit: "percent" },
      { name: "database_connections", value: 12, unit: "conn" },
      { name: "memory_usage_mb", value: 456, unit: "MB" }
    ]

    health_metrics.each do |m|
      3.times do |i|
        Management::SystemHealthSnapshot.find_or_create_by!(
          metric_name: m[:name],
          captured_at: i.hours.ago.beginning_of_hour
        ) do |s|
          s.value = m[:value] + rand(-10.0..10.0)
          s.unit = m[:unit]
          s.status = :healthy
        end
      end
    end

    # ── 12. Alerts ─────────────────────────────────────────────────────
    alert_templates = [
      { alert_type: "loan_delinquency", severity: :warning,
        title: "Delinquency rate alert",
        message: "#{branches.first&.name || coop.name} delinquency rate is elevated." },
      { alert_type: "system_health", severity: :info,
        title: "System operating normally",
        message: "All systems operational for #{coop.name}." }
    ]

    alert_templates.each do |attrs|
      Management::Alert.find_or_create_by!(
        alert_type: attrs[:alert_type],
        title: attrs[:title],
        severity: attrs[:severity],
        source: "system"
      ) do |a|
        a.message = attrs[:message]
        a.status = :active
      end
    end

    # ── 13. Configurations ─────────────────────────────────────────────
    {
      "loan_default_interest_rate" => { value: 1.5, unit: "percent" },
      "savings_base_interest_rate" => { value: 0.25, unit: "percent" },
      "max_loan_to_value_ratio" => { value: 80, unit: "percent" }
    }.each do |key, val|
      Management::Configuration.find_or_create_by!(key: key) do |c|
        c.value = val
        c.status = :active
        c.changed_by_id = admin_user&.id || 0
        c.approved_by_id = admin_user&.id || 0
        c.approved_at = Time.current
      end
    end

    # ── 14. Audit logs ─────────────────────────────────────────────────
    unless Management::AuditLog.exists?
      gm_user = coop_users.find { |u| u.role == "manager" } || admin_user

      [
        { action: "tenant_provisioned", auditable: nil, actor: gm_user },
        { action: "user_login", auditable: gm_user, actor: gm_user },
        { action: "data_seeded", auditable: nil, actor: admin_user }
      ].each_with_index do |attrs, i|
        Management::AuditLog.create!(
          auditable: attrs[:auditable],
          action: attrs[:action],
          actor: attrs[:actor],
          actor_role: attrs[:actor]&.management_roles&.first&.code,
          ip_address: "10.0.0.#{100 + idx}",
          user_agent: "SeedScript/1.0",
          before_state: {},
          after_state: { cooperative: coop.name, seeded_at: Time.current.iso8601 },
          created_at: (10 - i).minutes.ago
        )
      end
    end
  end
end

puts "\n✅ Demo data seeded for #{Cooperative.active.provisioned.count} cooperatives"
