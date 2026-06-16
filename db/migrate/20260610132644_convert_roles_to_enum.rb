class ConvertRolesToEnum < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :role, :integer, default: 0, null: false

    execute <<-SQL.squish
      UPDATE users
      SET role = CASE roles.name
        WHEN 'manager' THEN 0
        WHEN 'treasurer' THEN 1
        WHEN 'accountant' THEN 2
        WHEN 'loan_officer' THEN 3
        WHEN 'system_administrator' THEN 0
        WHEN 'teller' THEN 3
      END
      FROM roles
      WHERE users.role_id = roles.id
    SQL

    remove_reference :users, :role, foreign_key: true
    drop_table :roles
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
