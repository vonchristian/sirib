class CreateLoanCoMakers < ActiveRecord::Migration[8.0]
  def change
    create_table :loan_co_makers do |t|
      t.references :loan_application, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.timestamps
    end

    add_index :loan_co_makers, [:loan_application_id, :member_id], unique: true
  end
end
