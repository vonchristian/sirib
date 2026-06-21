class MembersController < ApplicationController
  layout "shell"

  TAB_ACTIONS = %w[overview savings time_deposits loans share_capital settings].freeze
  TAB_PERMISSIONS = {
    overview: :member,
    savings: :savings,
    time_deposits: :time_deposit,
    loans: :loan,
    share_capital: :share_capital,
    settings: :member
  }.freeze

  before_action :set_member, only: [ :show, :toggle_portal_access, *TAB_ACTIONS.map { |t| "tab_#{t}".to_sym } ]
  before_action :require_tab_permission, only: TAB_ACTIONS.map { |t| "tab_#{t}".to_sym }

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

  TAB_ACTIONS.each do |tab|
    define_method("tab_#{tab}") { show }
  end

  def show
    @summary = Members::ProfileSummaryService.new(@member).call

    case params[:tab]
    when "savings"
      @savings_summary = Members::SavingsSummaryService.new(@member).call
    when "time_deposits"
      @time_deposits = Treasury::TimeDeposit.where(
        depositor_id: @member.id, depositor_type: "Member"
      ).includes(:time_deposit_product).by_latest
    when "loans"
      @loan_summary = Members::LoanSummaryService.new(@member).call
    when "share_capital"
      @share_capital_accounts = Equity::Account.where(member: @member).includes(:share_product).by_latest
      @share_transactions = Equity::Transaction.where(
        share_capital_account_id: @share_capital_accounts.pluck(:id)
      ).includes(:share_capital_account).by_latest.limit(50)
    else
      @recent_activity = Members::RecentActivityService.new(@member).call
    end
  end

  def toggle_portal_access
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

  def edit
  end

  def update
    if @member.update(member_params)
      attach_files
      redirect_to @member, notice: "Member updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def deactivate
    if @member.update(portal_status: "suspended")
      redirect_to @member, notice: "Member has been deactivated."
    else
      redirect_to @member, alert: "Failed to deactivate member."
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

  def require_tab_permission
    action_name.match(/^tab_(.+)$/) do |m|
      subject = TAB_PERMISSIONS[m[1].to_sym]
      unless Current.user&.has_permission?("view", subject.to_s)
        redirect_to member_path(@member), alert: "You are not authorized to view this tab." and return
      end
    end
  end

  def set_member
    @member = Membership::Member.find(params[:id])
  end

  def member_params
    params.require(:member).permit(
      :first_name, :middle_name, :last_name, :suffix,
      :birth_date, :gender, :civil_status,
      :mobile_number, :email_address, :signature_data,
      address_attributes: [ :id, :house_street, :barangay, :city, :province, :region, :zip_code ],
      identifications_attributes: [ :id, :id_type, :id_number, :file ]
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
