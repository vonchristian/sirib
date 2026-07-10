class CreateReportingMaterializedViews < ActiveRecord::Migration[8.0]
  def up
    execute("SET timezone = 'UTC'")

    execute(<<~SQL)
      CREATE MATERIALIZED VIEW reporting_trial_balances AS
      SELECT
        al.account_id,
        a.account_code,
        a.name AS account_name,
        a.account_type,
        a.cooperative_id,
        COALESCE(SUM(CASE WHEN al.amount_type = 0 THEN al.amount_cents ELSE 0 END), 0) AS debit_cents,
        COALESCE(SUM(CASE WHEN al.amount_type = 1 THEN al.amount_cents ELSE 0 END), 0) AS credit_cents,
        COUNT(DISTINCT e.id) AS entry_count,
        MAX(e.posted_at) AS last_activity_at
      FROM amount_lines al
      JOIN entries e ON e.id = al.entry_id
      JOIN accounts a ON a.id = al.account_id
      WHERE e.status = 'posted'
      GROUP BY al.account_id, a.account_code, a.name, a.account_type, a.cooperative_id
      ORDER BY a.account_code
    SQL

    execute(<<~SQL)
      CREATE MATERIALIZED VIEW reporting_balance_sheets AS
      SELECT
        a.id AS account_id,
        a.account_code,
        a.name AS account_name,
        a.account_type,
        a.cooperative_id,
        COALESCE(rb.balance_cents, 0) AS balance_cents,
        COALESCE(rb.as_of_date, CURRENT_DATE) AS as_of_date
      FROM accounts a
      LEFT JOIN LATERAL (
        SELECT balance_cents, as_of_date
        FROM running_balances
        WHERE account_id = a.id
        ORDER BY as_of_date DESC
        LIMIT 1
      ) rb ON true
      WHERE a.account_type IN ('asset', 'liability', 'equity')
      ORDER BY a.account_code
    SQL

    execute(<<~SQL)
      CREATE MATERIALIZED VIEW reporting_loan_agings AS
      SELECT
        l.id AS loan_id,
        l.reference_number AS loan_number,
        l.cooperative_id,
        m.id AS member_id,
        CONCAT(COALESCE(m.last_name, ''), ', ', COALESCE(m.first_name, '')) AS member_name,
        l.outstanding_principal_cents,
        COALESCE(la.days_past_due, 0) AS days_past_due,
        COALESCE(la.total_exposure_cents, l.outstanding_principal_cents) AS total_exposure_cents,
        la.calculated_at AS last_aged_at,
        lag.name AS aging_group_name,
        (SELECT MAX(payment_date) FROM loan_payments WHERE loan_id = l.id) AS last_payment_date,
        CURRENT_DATE AS as_of_date
      FROM loans l
      LEFT JOIN members m ON m.id = l.member_id
      LEFT JOIN loan_agings la ON la.loan_id = l.id
      LEFT JOIN loan_aging_groups lag ON lag.id = la.loan_aging_group_id
      WHERE l.status IN ('active', 'defaulted') AND l.disbursed_at IS NOT NULL
    SQL

    execute("CREATE UNIQUE INDEX idx_rep_trial_balances ON reporting_trial_balances (account_id)")
    execute("CREATE UNIQUE INDEX idx_rep_balance_sheets ON reporting_balance_sheets (account_id)")
    execute("CREATE UNIQUE INDEX idx_rep_loan_agings ON reporting_loan_agings (loan_id)")
  end

  def down
    execute("DROP MATERIALIZED VIEW IF EXISTS reporting_trial_balances")
    execute("DROP MATERIALIZED VIEW IF EXISTS reporting_balance_sheets")
    execute("DROP MATERIALIZED VIEW IF EXISTS reporting_loan_agings")
  end
end