class RenameShareCapitalProductsToEquityProducts < ActiveRecord::Migration[8.0]
  def change
    rename_table :share_capital_products, :equity_products
  end
end
