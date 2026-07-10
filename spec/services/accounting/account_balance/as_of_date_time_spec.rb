require "rails_helper"

RSpec.describe Accounting::AccountBalance::AsOfDateTime do
  describe "#cutoff" do
    subject(:strategy) { described_class.new(to_date: date, to_time: time) }
    let(:date) { Date.new(2026, 7, 9) }
    let(:time) { Time.zone.parse("14:30:00") }

    it "returns an ActiveSupport::TimeWithZone" do
      expect(strategy.send(:cutoff)).to be_a(ActiveSupport::TimeWithZone)
    end

    it "uses the application timezone" do
      expect(strategy.send(:cutoff).time_zone).to eq(Time.zone)
    end

    it "combines date and time correctly" do
      expect(strategy.send(:cutoff)).to eq(Time.zone.local(2026, 7, 9, 14, 30, 0))
    end
  end
end