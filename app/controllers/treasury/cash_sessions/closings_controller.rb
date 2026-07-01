module Treasury
  module CashSessions
    class ClosingsController < ApplicationController
      layout "shell"

      DENOMINATIONS = [
        { amount: 100_000, label: "1,000.00" },
        { amount: 50_000,  label: "500.00" },
        { amount: 10_000,  label: "100.00" },
        { amount: 5_000,   label: "50.00" },
        { amount: 2_000,   label: "20.00" },
        { amount: 1_000,   label: "10.00" },
        { amount: 500,     label: "5.00" },
        { amount: 100,     label: "1.00" },
        { amount: 25,      label: "0.25" },
        { amount: 10,      label: "0.10" },
        { amount: 5,       label: "0.05" },
        { amount: 1,       label: "0.01" }
      ].freeze

      def new
        @session = Treasury::CashSession.find(params[:cash_session_id])

        if @session.closed?
          redirect_to treasury_cash_session_path(@session), alert: "This session is already closed."
          return
        end

        @expected_total = @session.computed_ending_balance
        @denominations = DENOMINATIONS
      end

      def create
        @session = Treasury::CashSession.find(params[:cash_session_id])

        if @session.closed?
          redirect_to treasury_cash_session_path(@session), alert: "This session is already closed."
          return
        end

        count_data = params[:counts] || {}
        @expected_total = @session.computed_ending_balance

        counts_data = []
        total_counted = 0
        DENOMINATIONS.each_with_index do |denom, index|
          count = (count_data[index.to_s] || 0).to_i
          total_counted += count * denom[:amount]
          counts_data << { label: denom[:label], amount: denom[:amount], count: count, subtotal: count * denom[:amount] }
        end

        variance = total_counted - @expected_total

        if variance.abs > 100
          redirect_to new_treasury_cash_session_closing_path(@session),
            alert: "Variance of #{number_to_currency(variance / 100.0)} detected. Please verify your counts."
          return
        end

        @session.close_with_count!(total_counted, notes: params[:notes], counts: counts_data)
        redirect_to download_pdf_treasury_cash_session_path(@session)
      rescue ActiveRecord::RecordInvalid => e
        redirect_to new_treasury_cash_session_closing_path(@session), alert: e.message
      end
    end
  end
end
