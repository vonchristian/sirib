require "rails_helper"

RSpec.describe "Append-only triggers" do
  before do
    Current.cooperative = create(:cooperative)
  end

  after do
    Current.reset
  end

  let(:cooperative) { Current.cooperative }
  let(:entry) { create(:accounting_entry, status: "posted") }

  def entry_row(attrs = {})
    ref = "TRIGGER-TEST-#{SecureRandom.hex(8)}"
    now = Time.current
    status = attrs.fetch(:status, "posted")
    ActiveRecord::Base.connection.execute(<<~SQL).first["id"]
      INSERT INTO entries (cooperative_id, reference_number, description, posted_at, status, created_at, updated_at)
      VALUES (#{cooperative.id}, '#{ref}', 'test entry', '#{now.iso8601}', '#{status}', '#{now.iso8601}', '#{now.iso8601}')
      RETURNING id
    SQL
  end

  def amount_line_row(entry_id:, account_id: nil)
    account_id ||= create_account!
    ActiveRecord::Base.connection.execute(<<~SQL).first["id"]
      INSERT INTO amount_lines (cooperative_id, entry_id, account_id, amount_type, amount_cents, amount_currency, created_at, updated_at)
      VALUES (#{cooperative.id}, #{entry_id}, #{account_id}, 0, 1000, 'PHP', NOW(), NOW())
      RETURNING id
    SQL
  end

  def running_balance_row(account_id: nil)
    account_id ||= create_account!
    ActiveRecord::Base.connection.execute(<<~SQL).first["id"]
      INSERT INTO running_balances (cooperative_id, account_id, ledger_id, as_of_date, balance_cents, balance_currency, created_at, updated_at)
      VALUES (#{cooperative.id}, #{account_id}, (SELECT ledger_id FROM accounts WHERE id = #{account_id}), CURRENT_DATE, 0, 'PHP', NOW(), NOW())
      RETURNING id
    SQL
  end

  def create_account!
    ledger_id = ActiveRecord::Base.connection.execute(<<~SQL).first["id"]
      INSERT INTO ledgers (cooperative_id, name, account_code, account_type, created_at, updated_at)
      VALUES (#{cooperative.id}, 'test-ledger-#{SecureRandom.hex(4)}', '#{SecureRandom.hex(6).upcase}', 'asset', NOW(), NOW())
      RETURNING id
    SQL
    ActiveRecord::Base.connection.execute(<<~SQL).first["id"]
      INSERT INTO accounts (cooperative_id, ledger_id, name, account_code, account_type, created_at, updated_at)
      VALUES (#{cooperative.id}, #{ledger_id}, 'test-account-#{SecureRandom.hex(4)}', '#{SecureRandom.hex(6).upcase}', 'asset', NOW(), NOW())
      RETURNING id
    SQL
  end

  describe "entries table" do
    it "blocks DELETE" do
      id = entry_row
      expect {
        ActiveRecord::Base.connection.execute("DELETE FROM entries WHERE id = #{id}")
      }.to raise_error(ActiveRecord::StatementInvalid, /Append-only table/)
    end

    it "blocks UPDATE on non-status columns" do
      id = entry_row
      expect {
        ActiveRecord::Base.connection.execute("UPDATE entries SET description = 'hacked' WHERE id = #{id}")
      }.to raise_error(ActiveRecord::StatementInvalid, /Append-only table/)
    end

    it "allows status transition from pending to posted" do
      pending_entry = create(:accounting_entry, status: "pending")
      expect {
        pending_entry.update!(status: "posted")
      }.not_to raise_error
      expect(pending_entry.reload.status).to eq("posted")
    end

    it "allows status transition from posted to reversed" do
      expect {
        entry.update!(status: "reversed", reversed_at: Time.current)
      }.not_to raise_error
      expect(entry.reload.status).to eq("reversed")
    end

    it "allows override for legitimate modifications" do
      id = entry_row
      expect {
        AppendOnlyOverride.with_override(reason: "data fix") do
          ActiveRecord::Base.connection.execute("UPDATE entries SET description = 'corrected' WHERE id = #{id}")
        end
      }.not_to raise_error
    end
  end

  describe "amount_lines table" do
    it "blocks DELETE" do
      eid = entry_row
      aid = create_account!
      lid = amount_line_row(entry_id: eid, account_id: aid)
      expect {
        ActiveRecord::Base.connection.execute("DELETE FROM amount_lines WHERE id = #{lid}")
      }.to raise_error(ActiveRecord::StatementInvalid, /Append-only table/)
    end

    it "blocks UPDATE" do
      eid = entry_row
      aid = create_account!
      lid = amount_line_row(entry_id: eid, account_id: aid)
      expect {
        ActiveRecord::Base.connection.execute("UPDATE amount_lines SET amount_cents = 999999 WHERE id = #{lid}")
      }.to raise_error(ActiveRecord::StatementInvalid, /Append-only table/)
    end

    it "allows override for legitimate modifications" do
      eid = entry_row
      aid = create_account!
      lid = amount_line_row(entry_id: eid, account_id: aid)
      expect {
        AppendOnlyOverride.with_override(reason: "data fix") do
          ActiveRecord::Base.connection.execute("UPDATE amount_lines SET amount_cents = 999999 WHERE id = #{lid}")
        end
      }.not_to raise_error
    end
  end

  describe "running_balances table" do
    it "blocks DELETE without override" do
      id = running_balance_row
      expect {
        ActiveRecord::Base.connection.execute("DELETE FROM running_balances WHERE id = #{id}")
      }.to raise_error(ActiveRecord::StatementInvalid, /Append-only table/)
    end

    it "blocks UPDATE without override" do
      id = running_balance_row
      expect {
        ActiveRecord::Base.connection.execute("UPDATE running_balances SET balance_cents = 0 WHERE id = #{id}")
      }.to raise_error(ActiveRecord::StatementInvalid, /Append-only table/)
    end

    it "allows DELETE with override" do
      id = running_balance_row
      expect {
        AppendOnlyOverride.with_override(reason: "rebuild") do
          ActiveRecord::Base.connection.execute("DELETE FROM running_balances WHERE id = #{id}")
        end
      }.not_to raise_error
    end

    it "allows UPDATE with override" do
      id = running_balance_row
      expect {
        AppendOnlyOverride.with_override(reason: "data fix") do
          ActiveRecord::Base.connection.execute("UPDATE running_balances SET balance_cents = 0 WHERE id = #{id}")
        end
      }.not_to raise_error
    end
  end

  describe "AppendOnlyOverride concern" do
    it "requires a reason" do
      expect {
        AppendOnlyOverride.with_override(reason: nil) { }
      }.to raise_error(ArgumentError, "reason is required")
    end

    it "sets the override flag during the block" do
      AppendOnlyOverride.with_override(reason: "test") do
        result = ActiveRecord::Base.connection.execute("SELECT current_setting('my.append_only_override')")
        expect(result.first["current_setting"]).to eq("on")
      end
    end
  end

  describe "Entry#reverse!" do
    it "continues to work with the append-only trigger" do
      expect {
        entry.reverse!(reversed_by: nil)
      }.not_to raise_error
      expect(entry.reload.status).to eq("reversed")
    end
  end
end
