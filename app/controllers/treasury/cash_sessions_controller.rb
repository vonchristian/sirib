module Treasury
  class CashSessionsController < ApplicationController
    layout "dashboard"

    def index
      @sessions = Treasury::CashSession.where(user: Current.user).by_latest
    end

    def show
      @session = Treasury::CashSession.find(params[:id])
      @vouchers = @session.vouchers.by_latest.includes(:cash_account, :entry, :counterparty)
      @receipts = @vouchers.receipts.posted
      @disbursements = @vouchers.disbursements.posted
    end

    def close
      @session = Treasury::CashSession.find(params[:id])
      @session.close!
      redirect_to treasury_cash_session_path(@session), notice: "Cash session closed."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to treasury_cash_session_path(@session), alert: e.message
    end
  end
end
