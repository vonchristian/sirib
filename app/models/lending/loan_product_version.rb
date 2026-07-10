module Lending
  class LoanProductVersion < ApplicationRecord
    self.table_name = "loan_product_versions"

    belongs_to :loan_product
    belongs_to :modified_by, class_name: "User", optional: true
  end
end
