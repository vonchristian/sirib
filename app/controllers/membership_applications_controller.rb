class MembershipApplicationsController < ApplicationController
  layout "dashboard"

  def index
    @applications = MembershipApplication.all
  end

  def new
    cooperative = Cooperative.first_or_create!(name: "Main Cooperative")
    application = cooperative.membership_applications.create!
    redirect_to edit_membership_application_path(application.uuid)
  end

  def edit
    @application = MembershipApplication.find_by!(uuid: params[:uuid])
    @initial_step = params[:step]&.to_i if params[:step]&.to_i&.between?(0, 4)
    @initial_step ||= @application.current_step
  end

  def update
    @application = MembershipApplication.find_by!(uuid: params[:uuid])

    if @application.update(application_params)
      if params[:commit] == "Complete Registration"
        @application.update(status: "completed") if @application.complete?
        redirect_to membership_application_path(@application.uuid), notice: "Application completed."
      else
        redirect_to edit_membership_application_path(@application.uuid, step: @application.current_step), notice: "Progress saved."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @application = MembershipApplication.find_by!(uuid: params[:uuid])
  end

  def approve
    @application = MembershipApplication.find_by!(uuid: params[:uuid])

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
      :signature_specimens, :profile_image_data, :current_step,
      identifications: [:id_type, :id_number]
    )
  end
end
