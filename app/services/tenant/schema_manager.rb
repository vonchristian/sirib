module Tenant
  class SchemaManager
    class SchemaError < StandardError; end

    SHARED_SCHEMA = "public"

    class << self
      def create_schema(schema_name)
        return if schema_exists?(schema_name)

        execute("CREATE SCHEMA #{quote_schema(schema_name)}")
        true
      end

      def drop_schema(schema_name)
        return unless schema_exists?(schema_name)
        return if schema_name == SHARED_SCHEMA

        execute("DROP SCHEMA #{quote_schema(schema_name)} CASCADE")
        true
      end

      def schema_exists?(schema_name)
        execute(<<-SQL.squish).first.present?
          SELECT schema_name
          FROM information_schema.schemata
          WHERE schema_name = #{ActiveRecord::Base.connection.quote(schema_name)}
        SQL
      end

      def switch_to(schema_name)
        execute("SET search_path TO #{quote_schema(schema_name)}, #{SHARED_SCHEMA}")
      end

      def switch_to_shared
        execute("SET search_path TO #{SHARED_SCHEMA}")
      end

      def within_schema(schema_name, &block)
        original = current_schema
        switch_to(schema_name)
        yield
      ensure
        switch_to(original) if original
      end

      def current_schema
        execute("SELECT current_schema()").first["current_schema"]
      end

      def clone_public_tables_to(schema_name)
        tables = public_tables

        tables.each do |table|
          execute(<<-SQL.squish)
            CREATE TABLE #{quote_schema(schema_name)}.#{table} (LIKE #{SHARED_SCHEMA}.#{table} INCLUDING ALL)
          SQL
        end

        tables.each do |table|
          relocate_sequences(table, schema_name)
        end

        within_schema(schema_name) do
          tables.each do |table|
            copy_foreign_keys(table, schema_name)
          end
        end
      end

      def public_tables
        execute(<<-SQL.squish)
          SELECT tablename
          FROM pg_tables
          WHERE schemaname = #{ActiveRecord::Base.connection.quote(SHARED_SCHEMA)}
            AND tablename NOT IN (#{shared_tables.map { |t| ActiveRecord::Base.connection.quote(t) }.join(",")})
          ORDER BY tablename
        SQL
          .map { |r| r["tablename"] }
      end

      def shared_tables
        %w[ar_internal_metadata schema_migrations cooperatives users sessions backup_codes trusted_devices mfa_attempt_logs active_storage_attachments active_storage_blobs active_storage_variant_records]
      end

      def load_schema_into(schema_name)
        switch_to(schema_name)
        ActiveRecord::Schema.verbose = false

        structure_path = Rails.root.join("db/structure.sql")
        schema_path = Rails.root.join("db/schema.rb")

        if structure_path.exist?
          execute(File.read(structure_path))
        elsif schema_path.exist?
          load(schema_path)
        end
      rescue => e
        raise SchemaError, "Failed to load schema into #{schema_name}: #{e.message}"
      ensure
        switch_to_shared
        ActiveRecord::Schema.verbose = true
      end

      def run_migrations_in(schema_name)
        switch_to(schema_name)
        migration_context = ActiveRecord::MigrationContext.new(
          ActiveRecord::Migrator.migrations_paths,
          ActiveRecord::SchemaMigration
        )
        migration_context.migrate
      ensure
        switch_to_shared
      end

      def copy_foreign_keys(table, schema_name)
        fk_query = <<-SQL.squish
          SELECT
            con.conname AS constraint_name,
            con.confrelid,
            pg_get_constraintdef(con.oid) AS constraint_def
          FROM pg_constraint con
          JOIN pg_class rel ON rel.oid = con.conrelid
          JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
          WHERE nsp.nspname = #{ActiveRecord::Base.connection.quote(SHARED_SCHEMA)}
            AND rel.relname = #{ActiveRecord::Base.connection.quote(table)}
            AND con.contype = 'f'
        SQL

        execute(fk_query).each do |row|
          constraint_name = "#{table}_#{row["constraint_name"]}"
          constraint_def = row["constraint_def"]

          ref_info = execute(<<-SQL.squish).first
            SELECT
              nsp.nspname AS schema_name,
              rel.relname AS table_name
            FROM pg_class rel
            JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE rel.oid = #{row["confrelid"]}
          SQL

          ref_table = ref_info["table_name"]

          target_schema = if execute(<<-SQL.squish).first["exists"]
            SELECT EXISTS(
              SELECT 1 FROM pg_tables
              WHERE schemaname = #{ActiveRecord::Base.connection.quote(schema_name)}
              AND tablename = #{ActiveRecord::Base.connection.quote(ref_table)}
            )
          SQL
            schema_name
          else
            ref_info["schema_name"]
          end

          qualified_ref = "#{quote_schema(target_schema)}.#{quote_identifier(ref_table)}"
          new_def = constraint_def.sub(
            /\bREFERENCES\s+(?:(?:\w+)\.)?#{Regexp.escape(ref_table)}\b/,
            "REFERENCES #{qualified_ref}"
          )

          execute(<<-SQL.squish)
            ALTER TABLE #{quote_schema(schema_name)}.#{quote_identifier(table)}
            ADD CONSTRAINT #{quote_identifier(constraint_name)} #{new_def}
          SQL
        rescue => e
          Rails.logger.warn("Could not copy FK #{constraint_name}: #{e.message}")
        end
      end

      def relocate_sequences(table, schema_name)
        seq_query = <<-SQL.squish
          SELECT
            seq.relname AS seq_name,
            col.attname AS col_name
          FROM pg_class seq
          JOIN pg_depend dep ON dep.objid = seq.oid
          JOIN pg_class tab ON tab.oid = dep.refobjid
          JOIN pg_namespace nsp ON nsp.oid = tab.relnamespace
          JOIN pg_attribute col ON col.attrelid = tab.oid AND col.attnum = dep.refobjsubid
          WHERE nsp.nspname = #{ActiveRecord::Base.connection.quote(SHARED_SCHEMA)}
            AND tab.relname = #{ActiveRecord::Base.connection.quote(table)}
            AND seq.relkind = 'S'
        SQL

        execute(seq_query).each do |row|
          new_seq_name = "#{schema_name}_#{row["seq_name"]}"

          execute(<<-SQL.squish)
            CREATE SEQUENCE IF NOT EXISTS #{quote_schema(schema_name)}.#{quote_identifier(new_seq_name)}
          SQL

          execute(<<-SQL.squish)
            ALTER TABLE #{quote_schema(schema_name)}.#{quote_identifier(table)}
            ALTER COLUMN #{quote_identifier(row["col_name"])}
            SET DEFAULT nextval('#{quote_schema(schema_name)}.#{quote_identifier(new_seq_name)}'::regclass)
          SQL
        end
      rescue => e
        Rails.logger.warn("Could not copy sequences for #{table}: #{e.message}")
      end

      private

      def execute(sql)
        ActiveRecord::Base.connection.execute(sql)
      end

      def quote_schema(name)
        ActiveRecord::Base.connection.quote_table_name(name)
      end

      def quote_identifier(name)
        ActiveRecord::Base.connection.quote_column_name(name)
      end
    end
  end
end
