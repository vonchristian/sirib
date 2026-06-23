class BackfillAccountStatus < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE accounts SET status = 'active' WHERE status IS NULL")
  end

  def down
    execute("UPDATE accounts SET status = NULL WHERE status = 'active'")
  end
end
