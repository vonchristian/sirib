class MembersController < ApplicationController
  layout "shell"

  def index
    members = Membership::Member.order(created_at: :desc)
    members = members.search(params[:q]) if params[:q].present?

    respond_to do |format|
      format.html do
        @pagy, @members = pagy(members, limit: 20)
        @total_members = Membership::Member.count
        @male_count = Membership::Member.where(gender: "male").count
        @female_count = Membership::Member.where(gender: "female").count
      end
      format.turbo_stream do
        @members = members.limit(20)
      end
    end
  end

  def show
    @member = Membership::Member.find(params[:id])
    @savings_accounts = Treasury::SavingsAccount.where(depositor_id: @member.id, depositor_type: "Member").includes(:savings_product).by_latest
    @time_deposits = Treasury::TimeDeposit.where(depositor_id: @member.id, depositor_type: "Member").includes(:time_deposit_product).by_latest
    @loans = Lending::Loan.where(member: @member).includes(:loan_product, :loan_payments).order(created_at: :desc)
    @loan_applications = Lending::LoanApplication.where(member: @member).order(created_at: :desc)
  end

  def toggle_portal_access
    @member = Membership::Member.find(params[:member_id] || params[:id])
    enabled = params[:enabled].to_s == "true"

    @member.toggle_portal_access!(enabled: enabled)

    respond_to do |format|
      format.html { redirect_to member_path(@member), notice: enabled ? "Portal access enabled." : "Portal access suspended." }
      format.turbo_stream { redirect_to member_path(@member), notice: enabled ? "Portal access enabled." : "Portal access suspended." }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to member_path(@member), alert: "Failed to update portal access: #{e.message}" }
      format.turbo_stream { redirect_to member_path(@member), alert: "Failed to update portal access: #{e.message}" }
    end
  end

  def new
    @member = Membership::Member.new
    @member.build_address
    @member.identifications.build
  end

  def create
    @member = Membership::Member.new(member_params)

    if @member.save
      attach_files
      redirect_to @member, notice: "Member registered successfully."
    else
      @member.build_address unless @member.address
      @member.identifications.build if @member.identifications.none?
      render :new, status: :unprocessable_entity
    end
  end

  private

  def member_params
    params.require(:member).permit(
      :first_name, :middle_name, :last_name, :suffix,
      :birth_date, :gender, :civil_status,
      :mobile_number, :email_address, :signature_data,
      address_attributes: [:id, :house_street, :barangay, :city, :province, :region, :zip_code],
      identifications_attributes: [:id, :id_type, :id_number, :file]
    )
  end

  def attach_files
    identifications_attrs = params.dig(:member, :identifications_attributes)
    if identifications_attrs
      identifications_attrs.each do |_, attrs|
        next if attrs[:file].blank?
        member_identification = @member.identifications.find_by(id_type: attrs[:id_type])
        member_identification&.file&.attach(attrs[:file])
      end
    end

    attach_signature
    @member.profile_image.attach(params.dig(:member, :profile_image)) if params.dig(:member, :profile_image).present?
  end

  def attach_signature
    data_url = params.dig(:member, :signature_data)
    return if data_url.blank?

    decoded = Base64.decode64(data_url.sub("data:image/png;base64,", ""))
    io = StringIO.new(decoded)
    @member.signatures.attach(io: io, filename: "signature.png", content_type: "image/png")
  end
end
