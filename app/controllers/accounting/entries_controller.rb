module Accounting
  class EntriesController < ApplicationController
    layout "dashboard"

    def index
      entries = Accounting::Entry.order(posted_at: :desc, id: :desc)
      entries = entries.search(params[:q]) if params[:q].present?
      entries = entries.up_to(params[:to_date].to_date) if params[:to_date].present?
      entries = entries.from_date(params[:from_date].to_date) if params[:from_date].present?

      respond_to do |format|
        format.html do
          @pagy, @entries = pagy(entries, limit: 25)
        end
        format.csv do
          @entries = entries.includes(amount_lines: :account)
          headers["Content-Disposition"] = "attachment; filename=\"journal_entries_#{Date.current}.csv\""
        end
      end
    end

    def show
      @entry = Accounting::Entry.includes(amount_lines: :account).find(params[:id])
    end

    def new
      @entry = Accounting::Entry.new
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
        Turbo::StreamsChannel.broadcast_refresh_to "accounting_balances"
        redirect_to accounting_entry_path(@entry), notice: "Entry created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def entry_params
      params.require(:entry).permit(:description, :posted_at, amount_lines_attributes: [:account_id, :direction, :amount_cents])
    end

    def parse_lines
      lines = params.dig(:entry, :amount_lines_attributes)
      return [[], []] unless lines

      lines = lines.values if lines.is_a?(ActionController::Parameters)
      lines = [lines] unless lines.is_a?(Array)

      debits = []
      credits = []

      lines.each do |line|
        next if line[:account_id].blank?

        account = Accounting::Account.find(line[:account_id])

        case line[:direction]
        when "debit"
          debits << { account: account, amount: (line[:amount_cents].to_f * 100).round } if line[:amount_cents].to_f.positive?
        when "credit"
          credits << { account: account, amount: (line[:amount_cents].to_f * 100).round } if line[:amount_cents].to_f.positive?
        end
      end

      [debits, credits]
    end
  end
end
