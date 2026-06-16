module Loans
  class ApplicationsController < ApplicationController
    layout "dashboard"

    STEP_KEYS = %w[loan_details sources_of_income co_makers collaterals repayment_schedule].freeze

    def index
      @applications = Lending::LoanApplication.order(created_at: :desc)
    end

    def new
      @application = Lending::LoanApplication.create!(
        cooperative: Cooperative.first,
        status: "draft",
        current_step: 0
      )
      redirect_to edit_loans_application_path(@application.uuid)
    end

    def edit
      @application = Lending::LoanApplication.find_by!(uuid: params[:uuid])
      @initial_step = if params[:step].present? && STEP_KEYS.include?(params[:step])
        STEP_KEYS.index(params[:step])
      else
        @application.current_step
      end
      @application.loan_collaterals.build if @application.loan_collaterals.empty?
      if @application.loan_co_makers.empty?
        2.times { @application.loan_co_makers.build }
      end
    end

    def update
      @application = Lending::LoanApplication.find_by!(uuid: params[:uuid])

      if params[:lending_loan_application][:loan_product_id].present?
        product = Lending::LoanProduct.find(params[:lending_loan_application][:loan_product_id])
        params[:lending_loan_application][:interest_rate] ||= product.interest_rate
      end

      if @application.update(application_params)
        if params[:commit] == "Generate Schedule"
          @application.generate_repayment_schedules!
          redirect_to edit_loans_application_path(@application.uuid, step: "repayment_schedule"), notice: "Repayment schedule generated."
        elsif params[:commit] == "Complete Application"
          if @application.complete?
            @application.update(status: "submitted", submitted_at: Time.current)
            redirect_to loans_application_path(@application.uuid), notice: "Application submitted."
          else
            incomplete = @application.first_incomplete_step
            step_name = Lending::LoanApplication::STEP_LABELS[incomplete] || "Unknown"
            redirect_to edit_loans_application_path(@application.uuid, step: Lending::LoanApplication::STEP_KEYS[incomplete]),
              alert: "Please complete '#{step_name}' before submitting."
          end
        else
          redirect_to edit_loans_application_path(@application.uuid, step: STEP_KEYS[@application.current_step]), notice: "Progress saved."
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def show
      @application = Lending::LoanApplication.find_by!(uuid: params[:uuid])
    end

    def submit
      @application = Lending::LoanApplication.find_by!(uuid: params[:uuid])
      if @application.complete?
        @application.update(status: "submitted", submitted_at: Time.current)
        redirect_to loans_application_path(@application.uuid), notice: "Application submitted for review."
      else
        redirect_to edit_loans_application_path(@application.uuid), alert: "Complete all steps first."
      end
    end

    def download_pdf
      @application = Lending::LoanApplication.find_by!(uuid: params[:uuid])
      html = render_to_string("download_pdf", layout: "pdf")
      pdf = Grover.new(html, format: "Letter").to_pdf
      send_data pdf,
        filename: "loan_application_#{@application.uuid.first(8)}.pdf",
        type: "application/pdf",
        disposition: "attachment"
    end

    private

    def application_params
      params.require(:lending_loan_application).permit(
        :member_id, :loan_product_id, :amount_cents, :interest_rate, :term_months, :current_step, :notes,
        :sources_of_income,
        loan_collaterals_attributes: [
          :id, :category, :name, :description, :assessed_value_cents, :pin_lat, :pin_lng, :address, :details, :_destroy,
          images: []
        ],
        loan_co_makers_attributes: [
          :id, :member_id, :_destroy
        ]
      )
    end
  end
end
