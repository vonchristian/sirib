namespace :test do
  desc "Create custom SQL objects not captured by schema.rb"
  task setup_custom_sql: :environment do
    raise "Only run in test environment" unless Rails.env.test?

    conn = ActiveRecord::Base.connection

    conn.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")

    conn.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION block_append_only_modifications()
      RETURNS TRIGGER AS $$
      DECLARE
        override_text text;
        override_active boolean;
      BEGIN
        BEGIN
          override_text := current_setting('my.append_only_override');
        EXCEPTION WHEN OTHERS THEN
          override_text := NULL;
        END;

        override_active := CASE
          WHEN override_text IS NULL OR override_text = '' THEN false
          ELSE lower(override_text) IN ('true', '1', 'yes', 'on')
        END;

        IF TG_OP = 'DELETE' THEN
          IF NOT override_active THEN
            RAISE EXCEPTION 'Append-only table: DELETE not permitted on %', TG_TABLE_NAME;
          END IF;
          RETURN OLD;
        END IF;

        IF TG_OP = 'UPDATE' THEN
          IF TG_TABLE_NAME = 'entries' THEN
            IF (OLD.status = 'pending' AND NEW.status = 'posted') OR
               (OLD.status = 'posted' AND NEW.status = 'reversed') THEN
              RETURN NEW;
            END IF;
          END IF;

          IF NOT override_active THEN
            RAISE EXCEPTION 'Append-only table: UPDATE not permitted on %', TG_TABLE_NAME;
          END IF;
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    %w[entries amount_lines running_balances loan_payments loan_schedules
       loan_events treasury_savings_transactions equity_transactions].each do |table|
      conn.execute(<<~SQL)
        DROP TRIGGER IF EXISTS trg_#{table}_append_only ON #{table};
        CREATE TRIGGER trg_#{table}_append_only
          BEFORE UPDATE OR DELETE ON #{table}
          FOR EACH ROW EXECUTE FUNCTION block_append_only_modifications();
      SQL
    end

    conn.execute(<<~SQL)
      CREATE MATERIALIZED VIEW IF NOT EXISTS reporting_trial_balances AS
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

    conn.execute(<<~SQL)
      CREATE MATERIALIZED VIEW IF NOT EXISTS reporting_balance_sheets AS
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

    conn.execute(<<~SQL)
      CREATE MATERIALIZED VIEW IF NOT EXISTS reporting_loan_agings AS
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

    conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_rep_trial_balances ON reporting_trial_balances (account_id)")
    conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_rep_balance_sheets ON reporting_balance_sheets (account_id)")
    conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_rep_loan_agings ON reporting_loan_agings (loan_id)")

    puts "Custom SQL objects created successfully"
  end
end
