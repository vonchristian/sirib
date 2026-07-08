require "rails_helper"

RSpec.describe PasswordsMailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:mail) { described_class.reset(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Reset your password")
      expect(mail.to).to eq([ user.email_address ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to be_present
    end
  end
end
