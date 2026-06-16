class ApproveMembershipApplication
  def self.call(application)
    new(application).call
  end

  def initialize(application)
    @application = application
  end

  def call
    ActiveRecord::Base.transaction do
      member = create_member
      create_address(member)
      create_identifications(member)
      attach_signature(member)
      attach_profile_image(member)
      @application.update!(status: "approved")
      member
    end
  end

  private

  def create_member
    Member.create!(
      first_name: @application.first_name,
      middle_name: @application.middle_name,
      last_name: @application.last_name,
      suffix: @application.suffix,
      birth_date: @application.birth_date,
      gender: @application.gender,
      civil_status: @application.civil_status,
      mobile_number: @application.mobile_number,
      email_address: @application.email_address
    )
  end

  def create_address(member)
    MemberAddress.create!(
      member: member,
      house_street: @application.house_street,
      barangay: @application.barangay,
      city: @application.city,
      province: @application.province,
      region: @application.region,
      zip_code: @application.zip_code
    )
  end

  def create_identifications(member)
    @application.identifications.each do |id|
      MemberIdentification.create!(
        member: member,
        id_type: id["id_type"],
        id_number: id["id_number"]
      )
    end
  end

  def attach_signature(member)
    specimens = @application.signature_specimens
    return if specimens.blank?

    specimens.each_with_index do |data, index|
      next if data.blank?
      decoded = Base64.decode64(data.sub("data:image/png;base64,", ""))
      io = StringIO.new(decoded)
      member.signatures.attach(io: io, filename: "signature_#{index + 1}.png", content_type: "image/png")
    end
  end

  def attach_profile_image(member)
    images = @application.profile_images
    return if images.blank?

    images.each_with_index do |data, index|
      next if data.blank?
      decoded = Base64.decode64(data.sub("data:image/png;base64,", ""))
      io = StringIO.new(decoded)
      member.profile_image.attach(io: io, filename: "profile_#{index + 1}.png", content_type: "image/png")
    end
  end
end
