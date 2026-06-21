module External
  class BankDocument < ApplicationRecord
    self.table_name = "external_bank_documents"
    include CooperativeScoped

    belongs_to :account, class_name: "External::BankAccount", foreign_key: :external_bank_account_id

    has_many :transactions, class_name: "External::BankTransaction", foreign_key: :external_bank_document_id, dependent: :nullify
    has_one_attached :file

    enum :document_type, { statement: "statement", export: "export", passbook_scan: "passbook_scan" }, default: :statement
    enum :processing_status, { pending: "pending", processing: "processing", parsed: "parsed", failed: "failed" }, default: :pending

    validates :document_type, presence: true

    scope :pending_processing, -> { where(processing_status: :pending) }
    scope :failed, -> { where(processing_status: :failed) }

    def period
      return nil unless period_start && period_end

      "#{period_start.strftime("%b %d, %Y")} - #{period_end.strftime("%b %d, %Y")}"
    end

    def file_url
      return nil unless file.attached?

      Rails.application.routes.url_helpers.rails_blob_url(file, only_path: true)
    end

    def mark_as_processing!
      update!(processing_status: :processing)
    end

    def mark_as_parsed!
      update!(processing_status: :parsed)
    end

    def mark_as_failed!(error_message)
      update!(processing_status: :failed, error_message: error_message)
    end
  end
end