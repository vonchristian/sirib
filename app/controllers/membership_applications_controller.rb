class MembershipApplicationsController < ApplicationController
  layout "shell"

  STEP_KEYS = %w[personal_details address_contact identifications sources_of_income signature_specimens profile_photos].freeze

  def index
    @applications = Membership::Application.all
  end

  def new
    cooperative = Cooperative.first_or_create!(name: "Main Cooperative")
    application = cooperative.membership_applications.create!
    redirect_to edit_membership_application_path(application.uuid)
  end

  def edit
    @application = Membership::Application.find_by!(uuid: params[:uuid])
    @initial_step = if params[:step].present? && STEP_KEYS.include?(params[:step])
      STEP_KEYS.index(params[:step])
    else
      @application.current_step
    end
  end

  def update
    @application = Membership::Application.find_by!(uuid: params[:uuid])

    if @application.update(application_params)
      if params[:commit] == "Complete Registration"
        @application.update(status: "completed") if @application.complete?
        redirect_to membership_application_path(@application.uuid), notice: "Application completed."
      else
        redirect_to edit_membership_application_path(@application.uuid, step: STEP_KEYS[@application.current_step]), notice: "Progress saved."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @application = Membership::Application.find_by!(uuid: params[:uuid])
  end

  def download_pdf
    @application = Membership::Application.find_by!(uuid: params[:uuid])
    html = render_to_string("download_pdf", layout: "pdf")
    pdf = Grover.new(html, format: "Letter").to_pdf
    send_data pdf,
      filename: "membership_application_#{@application.uuid.first(8)}.pdf",
      type: "application/pdf",
      disposition: "attachment"
  end

  def approve
    @application = Membership::Application.find_by!(uuid: params[:uuid])

    unless @application.complete?
      return redirect_to membership_application_path(@application.uuid),
        alert: "Complete all steps before approving."
    end

    member = ApproveMembershipApplication.call(@application)
    redirect_to member, notice: "Membership approved. Member registered successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to membership_application_path(@application.uuid),
      alert: "Approval failed: #{e.message}"
  end

  private

  def application_params
    params.require(:membership_application).permit(
      :first_name, :middle_name, :last_name, :suffix,
      :birth_date, :gender, :civil_status,
      :mobile_number, :email_address,
      :house_street, :barangay, :city, :province, :region, :zip_code,
      :signature_specimens, :profile_images, :sources_of_income, :current_step,
      identifications: [:id_type, :id_number, :front_image, :back_image],
      sources_of_income: [:source_type, :monthly_income]
    )
  end
end
