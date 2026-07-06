class AddAppendOnlyTriggers < ActiveRecord::Migration[8.0]
  APPEND_ONLY_TABLES = %w[
    entries
    amount_lines
    running_balances
    loan_payments
    loan_schedules
    loan_events
    treasury_savings_transactions
    equity_transactions
  ].freeze

  def up
    execute(<<~SQL)
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

    APPEND_ONLY_TABLES.each do |table|
      execute(<<~SQL)
        DROP TRIGGER IF EXISTS trg_#{table}_append_only ON #{table};
        CREATE TRIGGER trg_#{table}_append_only
          BEFORE UPDATE OR DELETE ON #{table}
          FOR EACH ROW EXECUTE FUNCTION block_append_only_modifications();
      SQL
    end
  end

  def down
    APPEND_ONLY_TABLES.each do |table|
      execute("DROP TRIGGER IF EXISTS trg_#{table}_append_only ON #{table}")
    end
    execute("DROP FUNCTION IF EXISTS block_append_only_modifications")
  end
end
