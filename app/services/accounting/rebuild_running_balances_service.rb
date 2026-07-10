module Accounting
  class RebuildRunningBalancesService < ActiveInteraction::Base
    TEMP_TABLE = "running_balances_new"

    def execute
      create_temp_table
      rebuild_into_temp
      swap_tables
      adopt_sequence
      recreate_trigger
      drop_old_table
    end

    private

    def create_temp_table
      execute_sql("DROP TABLE IF EXISTS #{TEMP_TABLE}")
      execute_sql("CREATE TABLE #{TEMP_TABLE} (LIKE running_balances INCLUDING ALL INCLUDING DEFAULTS)")
    end

    def rebuild_into_temp
      Accounting::Entry.order(posted_at: :asc).find_each do |entry|
        posted_date = entry.posted_at.to_date

        entry.accounts.distinct.each do |account|
          balance_cents = account.balance(to_date: posted_date).cents
          upsert_into_temp(
            account_id: account.id,
            ledger_id: account.ledger_id,
            as_of_date: posted_date,
            balance_cents: balance_cents
          )
        end

        entry.accounts.includes(:ledger).distinct.map(&:ledger).uniq.each do |ledger|
          balance_cents = ledger.balance(to_date: posted_date)
          upsert_into_temp(
            account_id: nil,
            ledger_id: ledger.id,
            as_of_date: posted_date,
            balance_cents: balance_cents
          )
        end
      end
    end

    def upsert_into_temp(account_id:, ledger_id:, as_of_date:, balance_cents:)
      if account_id
        execute_sql(<<~SQL)
          INSERT INTO #{TEMP_TABLE}
            (cooperative_id, account_id, ledger_id, as_of_date, balance_cents, balance_currency, created_at, updated_at)
          VALUES (#{Current.cooperative.id}, #{account_id}, #{ledger_id}, '#{as_of_date}', #{balance_cents}, 'PHP', NOW(), NOW())
          ON CONFLICT (account_id, as_of_date) WHERE account_id IS NOT NULL
          DO UPDATE SET balance_cents = EXCLUDED.balance_cents, ledger_id = EXCLUDED.ledger_id, updated_at = NOW()
        SQL
      else
        execute_sql(<<~SQL)
          INSERT INTO #{TEMP_TABLE}
            (cooperative_id, account_id, ledger_id, as_of_date, balance_cents, balance_currency, created_at, updated_at)
          VALUES (#{Current.cooperative.id}, NULL, #{ledger_id}, '#{as_of_date}', #{balance_cents}, 'PHP', NOW(), NOW())
          ON CONFLICT (ledger_id, as_of_date) WHERE account_id IS NULL
          DO UPDATE SET balance_cents = EXCLUDED.balance_cents, updated_at = NOW()
        SQL
      end
    end

    def swap_tables
      execute_sql("ALTER TABLE running_balances RENAME TO running_balances_old")
      execute_sql("ALTER TABLE #{TEMP_TABLE} RENAME TO running_balances")
    end

    def adopt_sequence
      execute_sql("ALTER SEQUENCE running_balances_id_seq OWNED BY running_balances.id")
    end

    def recreate_trigger
      execute_sql(<<~SQL)
        DROP TRIGGER IF EXISTS trg_running_balances_append_only ON running_balances;
        CREATE TRIGGER trg_running_balances_append_only
          BEFORE UPDATE OR DELETE ON running_balances
          FOR EACH ROW EXECUTE FUNCTION block_append_only_modifications();
      SQL
    end

    def drop_old_table
      execute_sql("DROP TABLE IF EXISTS running_balances_old CASCADE")
    end

    def execute_sql(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
