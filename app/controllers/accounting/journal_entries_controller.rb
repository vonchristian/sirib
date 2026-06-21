module Accounting
  class JournalEntriesController < ApplicationController
    layout "shell"

    def index
      @filters = build_filters
      @query_service = JournalEntryQueryService.new(@filters)
      @entries = @query_service.call

      @pagy, @entries = pagy(@entries, limit: 25)

      @branches = Management::Branch.active.order(:name) if Entry.column_names.include?("branch_id")
      @accounts = Accounting::Account.order(:name).limit(100)
      @users = User.order(:full_name).limit(50)
      @saved_filters = SavedFilterService.new(user: Current.user).list(filter_type: "journal_entry")

      respond_to do |format|
        format.html
        format.turbo_stream
        format.csv do
          export_service = JournalReportService.new(
            start_date: @filters[:start_date] || 1.month.ago,
            end_date: @filters[:end_date] || Date.current,
            branch_id: @filters[:branch_id],
            account_id: @filters[:account_id],
            report_type: :journal_summary
          )
          send_data export_service.to_csv, filename: "journal_entries_#{Date.current.iso8601}.csv"
        end
      end
    end

    def show
      @entry = Accounting::Entry.includes(amount_lines: :account).find(params[:id])
      @entry_template = Accounting::EntryTemplate.find_by(entry_id: @entry.id)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def new
      @templates = Accounting::EntryTemplate.active.order(:name)
      @preview_lines = []
      @branches = Management::Branch.active.order(:name) if Entry.column_names.include?("branch_id")
    end

    def preview
      @template = Accounting::EntryTemplate.find(params[:template_id])
      engine = PostingEngine.new(template: @template, input: { amount: params[:amount] })
      @preview_lines = engine.preview

      render partial: "accounting/journal_entries/preview_lines", locals: { lines: @preview_lines }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    def create
      @template = Accounting::EntryTemplate.find(params[:template_id])
      engine = PostingEngine.new(template: @template, input: { amount: params[:amount] }, actor: Current.user)
      @entry = engine.post!

      redirect_to accounting_journal_entry_path(@entry), notice: "Journal entry posted successfully."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_accounting_journal_entry_path, alert: e.record.errors.full_messages.join(", ")
    rescue ValidationEngine::ValidationError => e
      redirect_to new_accounting_journal_entry_path, alert: e.message
    end

    def search
      @search_service = JournalEntrySearchService.new(
        query: params[:q],
        account_id: params[:account_id],
        member_id: params[:member_id]
      )
      @entries = @search_service.call

      @pagy, @entries = pagy(@entries, limit: 25)

      render :index
    end

    def saved_filters
      @saved_filter_service = SavedFilterService.new(user: Current.user)
      @filters_list = @saved_filter_service.list(filter_type: "journal_entry")

      render partial: "accounting/journal_entries/saved_filters_list", locals: { filters: @filters_list }
    end

    def save_filter
      @saved_filter_service = SavedFilterService.new(user: Current.user)
      @filter = @saved_filter_service.create!(
        name: params[:name],
        filters: build_filters,
        filter_type: "journal_entry",
        is_shared: params[:is_shared] == "true",
        set_default: params[:set_default] == "true"
      )

      redirect_to accounting_journal_entries_path, notice: "Filter saved successfully."
    rescue => e
      redirect_to accounting_journal_entries_path, alert: e.message
    end

    def apply_filter
      @saved_filter_service = SavedFilterService.new(user: Current.user)
      @applied_filters = @saved_filter_service.apply_saved_filter(params[:filter_id])

      redirect_to accounting_journal_entries_path(@applied_filters)
    rescue => e
      redirect_to accounting_journal_entries_path, alert: e.message
    end

    def reverse
      @entry = Accounting::Entry.find(params[:id])

      if @entry.reverse!(reversed_by: Current.user)
        redirect_to accounting_journal_entry_path(@entry), notice: "Entry reversed successfully."
      else
        redirect_to accounting_journal_entry_path(@entry), alert: "Cannot reverse this entry."
      end
    end

    private

    def build_filters
      {
        start_date: parse_date(params[:start_date]),
        end_date: parse_date(params[:end_date]),
        branch_id: params[:branch_id].presence,
        account_id: params[:account_id].presence,
        entry_type: params[:entry_type].presence,
        status: params[:status].presence,
        source_module: params[:source_module].presence,
        amount_min: params[:amount_min].presence,
        amount_max: params[:amount_max].presence,
        reference_number: params[:reference_number].presence,
        created_by_id: params[:created_by_id].presence,
        template_id: params[:template_id].presence,
        has_attachments: parse_boolean(params[:has_attachments]),
        inter_branch: parse_boolean(params[:inter_branch])
      }.compact
    end

    def parse_date(value)
      return nil if value.blank?
      Date.parse(value)
    rescue Date::Error
      nil
    end

    def parse_boolean(value)
      return nil if value.blank?
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
