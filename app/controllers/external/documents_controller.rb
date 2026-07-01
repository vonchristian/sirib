module External
  class DocumentsController < BaseController
    before_action { set_active_nav }
    before_action :set_bank
    before_action :set_account
    before_action :set_document, only: [ :show, :retry, :destroy ]

    def index
      @documents = @account.documents.order(created_at: :desc).with_attached_file
    end

    def new
      @document = @account.documents.new
    end

    def create
      @document = @account.documents.new(document_params)

      if @document.save
        External::ParseBankDocumentJob.perform_later(@document)

        redirect_to external_bank_account_documents_path(@bank, @account),
                    notice: "Document uploaded successfully. Processing will begin shortly."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @transactions = @document.transactions.by_date_desc
    end

    def retry
      @document.update!(processing_status: :pending, error_message: nil)
      External::ParseBankDocumentJob.perform_later(@document)
      redirect_to external_bank_account_document_path(@bank, @account, @document),
                  notice: "Document is being reprocessed."
    end

    def destroy
      @document.file.purge if @document.file.attached?
      @document.destroy!

      redirect_to external_bank_account_documents_path(@bank, @account),
                  notice: "Document was successfully deleted."
    end

    private

    def set_bank
      @bank = External::Bank.find(params[:bank_id])
    end

    def set_account
      @account = @bank.accounts.find(params[:account_id])
    end

    def set_document
      @document = @account.documents.find(params[:id])
    end

    def document_params
      params.require(:external_bank_document).permit(
        :file,
        :document_type,
        :period_start,
        :period_end
      )
    end
  end
end
