module Management
  class BranchPerformanceSnapshot < ApplicationRecord
    self.table_name = "management_branch_performance_snapshots"
    include CooperativeScoped

    belongs_to :branch, class_name: "Management::Branch"

    validates :snapshot_date, presence: true
    validates :snapshot_date, uniqueness: { scope: :branch_id }
  end
end
