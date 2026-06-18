module Treasury
  class VaultTransfersController < ApplicationController
    layout "dashboard"

    before_action :require_treasurer

    def index
      @transfers = Treasury::VaultTransfer.awaiting
        .includes(cash_session: :user)
        .order(created_at: :desc)
    end

    def approve
      @transfer = Treasury::VaultTransfer.find(params[:id])
      result = Treasury::VaultTransferService.approve(@transfer, approver: Current.user)

      if result.success?
        redirect_to treasury_vault_transfers_path, notice: "Transfer approved."
      else
        redirect_to treasury_vault_transfers_path, alert: result.errors.join(", ")
      end
    end

    def reject
      @transfer = Treasury::VaultTransfer.find(params[:id])
      result = Treasury::VaultTransferService.reject(@transfer, approver: Current.user)

      if result.success?
        redirect_to treasury_vault_transfers_path, notice: "Transfer rejected."
      else
        redirect_to treasury_vault_transfers_path, alert: result.errors.join(", ")
      end
    end

    private

    def require_treasurer
      unless Current.user&.treasurer?
        redirect_to treasury_cash_sessions_path, alert: "Only treasurers can manage vault transfers."
      end
    end
  end
end
