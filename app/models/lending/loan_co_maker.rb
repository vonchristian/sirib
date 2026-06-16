module Lending
  class LoanCoMaker < ApplicationRecord
    self.table_name = "loan_co_makers"

    belongs_to :loan_application
    belongs_to :member

    validates :member_id, uniqueness: { scope: :loan_application_id, message: "already added as co-maker" }
  end
end
