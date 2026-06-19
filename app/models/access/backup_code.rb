module Access
  class BackupCode < ApplicationRecord
    self.table_name = "backup_codes"

    belongs_to :user

    scope :unused, -> { where(used_at: nil) }
    scope :used, -> { where.not(used_at: nil) }
  end
end
