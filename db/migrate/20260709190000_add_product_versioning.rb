class AddProductVersioning < ActiveRecord::Migration[8.0]
  def up
    add_column :loan_products, :version, :integer, default: 1, null: false

    create_table :loan_product_versions do |t|
      t.references :loan_product, null: false, foreign_key: true
      t.integer :version, null: false
      t.jsonb :snapshot, null: false, default: {}
      t.references :modified_by, foreign_key: { to_table: :users }
      t.text :change_reason
      t.timestamps
    end

    add_index :loan_product_versions, %i[loan_product_id version], unique: true,
              name: "idx_loan_product_versions_on_product_and_version"

    add_column :loans, :product_snapshot, :jsonb, default: {}, null: false

    Lending::LoanProduct.reset_column_information
    Lending::Loan.reset_column_information

    Lending::LoanProduct.find_each do |product|
      snapshot = product.attributes.except("id", "cooperative_id", "created_at", "updated_at")
      execute "INSERT INTO loan_product_versions (loan_product_id, version, snapshot, change_reason, created_at, updated_at) VALUES (#{product.id}, 1, #{connection.quote(snapshot.to_json)}, #{connection.quote('Initial version (backfill)')}, NOW(), NOW())"
    end

    Lending::Loan.find_each do |loan|
      snapshot = loan.loan_product.attributes.except("id", "cooperative_id", "created_at", "updated_at")
      execute "UPDATE loans SET product_snapshot = #{connection.quote(snapshot.to_json)} WHERE id = #{loan.id}"
    end
  end

  def down
    remove_column :loans, :product_snapshot
    drop_table :loan_product_versions
    remove_column :loan_products, :version
  end
end
