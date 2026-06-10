module Accounting
  class EntriesController < ApplicationController
    layout "dashboard"

    def new
      @entry = Accounting::Entry.new
      @accounts = Accounting::Account.order(:account_code).includes(:ledger)
    end

    def create
      debits, credits = parse_lines

      @entry = Accounting::Entry.build(
        description: entry_params[:description],
        posted_at: entry_params[:posted_at].presence&.to_time || Time.current,
        debits: debits,
        credits: credits
      )

      if @entry.save
        redirect_to new_accounting_entry_path, notice: "Entry created successfully."
      else
        @accounts = Accounting::Account.order(:account_code).includes(:ledger)
        render :new, status: :unprocessable_entity
      end
    end

    private

    def entry_params
      params.require(:entry).permit(:description, :posted_at, lines: [:account_id, :debit_amount, :credit_amount])
    end

    def parse_lines
      lines = params[:entry][:lines]
      return [[], []] unless lines

      lines = lines.values if lines.is_a?(ActionController::Parameters)
      lines = [lines] unless lines.is_a?(Array)

      debits = []
      credits = []

      lines.each do |line|
        next if line[:account_id].blank?

        account = Accounting::Account.find(line[:account_id])

        if line[:debit_amount].present? && (val = line[:debit_amount].to_f).positive?
          debits << { account: account, amount: (val * 100).round }
        end

        if line[:credit_amount].present? && (val = line[:credit_amount].to_f).positive?
          credits << { account: account, amount: (val * 100).round }
        end
      end

      [debits, credits]
    end
  end
end
