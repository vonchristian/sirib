module Management
  class EntryTemplatesController < BaseController
    before_action :set_template, only: [ :show, :edit, :update, :preview, :execute ]

    def index
      @templates = Accounting::EntryTemplate.order(created_at: :desc)
      @pagy, @templates = pagy(@templates)
    end

    def show
      @lines = @template.lines.by_sequence.includes(:account)
    end

    def new
      @template = Accounting::EntryTemplate.new
      @template.lines.build
    end

    def create
      @template = Accounting::EntryTemplate.new(template_params)

      if @template.save
        redirect_to management_entry_template_path(@template), notice: "Template created successfully."
      else
        @template.lines.build if @template.lines.empty?
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @template.lines.build if @template.lines.empty?
    end

    def update
      if @template.update(template_params)
        redirect_to management_entry_template_path(@template), notice: "Template updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def preview
      amount = params[:amount].to_f
      outcome = Accounting::EntryTemplate::ExecuteService.run(template: @template, amount: amount)

      if outcome.valid?
        lines = outcome.result
        render partial: "management/entry_templates/preview_lines", locals: { lines: lines, amount: params[:amount] }
      else
        render json: { error: outcome.errors.full_messages.join(", ") }, status: :unprocessable_content
      end
    end

    def execute
      amount = params[:amount].to_f
      entry = Accounting::EntryTemplate::ExecuteService.run!(template: @template, amount: amount, posting: true, user: Current.user)

      redirect_to management_entry_template_path(@template), notice: "Journal entry ##{entry.id} posted successfully."
    rescue ActiveInteraction::InvalidInteractionError => e
      redirect_to management_entry_template_path(@template), alert: e.message
    end

    private

    def set_template
      @template = Accounting::EntryTemplate.find(params[:id])
    end

    def template_params
      params.require(:accounting_entry_template).permit(:name, :description, :is_active,
        lines_attributes: [ :id, :account_id, :direction, :amount_mode, :fixed_amount, :sequence_index, :_destroy ])
    end
  end
end
