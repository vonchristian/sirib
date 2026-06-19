class AddCooperativeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :cooperative, null: true, foreign_key: true

    reversible do |dir|
      dir.up do
        cooperative = Cooperative.first
        if cooperative
          User.where(cooperative_id: nil).update_all(cooperative_id: cooperative.id)
        end
        change_column_null :users, :cooperative_id, false
      end
    end
  end
end
