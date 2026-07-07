require "rails_helper"

RSpec.describe Management::BusinessDayService do
  let(:cooperative) { create(:cooperative) }
  subject(:service) { described_class.new(cooperative: cooperative) }

  describe "#business_day?" do
    it "returns true for a weekday" do
      wednesday = Date.new(2026, 7, 8) # Wednesday
      expect(service.business_day?(wednesday)).to be true
    end

    it "returns false for Saturday" do
      saturday = Date.new(2026, 7, 11)
      expect(service.business_day?(saturday)).to be false
    end

    it "returns false for Sunday" do
      sunday = Date.new(2026, 7, 12)
      expect(service.business_day?(sunday)).to be false
    end

    it "returns false for a holiday" do
      create(:management_holiday, date: Date.new(2026, 7, 8), name: "Test Holiday", cooperative: cooperative)
      expect(service.business_day?(Date.new(2026, 7, 8))).to be false
    end

    it "returns false for a recurring holiday" do
      create(:management_holiday, date: Date.new(2025, 12, 25), name: "Christmas", recurring: true, cooperative: cooperative)
      expect(service.business_day?(Date.new(2026, 12, 25))).to be false
    end
  end

  describe "#within_business_hours?" do
    it "returns true during business hours on a weekday" do
      Time.use_zone("UTC") do
        time_in = Time.zone.local(2026, 7, 8, 10, 0, 0) # Wednesday 10:00 AM
        expect(service.within_business_hours?(time_in)).to be true
      end
    end

    it "returns false before business hours" do
      Time.use_zone("UTC") do
        time_early = Time.zone.local(2026, 7, 8, 6, 0, 0) # 6:00 AM
        expect(service.within_business_hours?(time_early)).to be false
      end
    end

    it "returns false after business hours" do
      Time.use_zone("UTC") do
        time_late = Time.zone.local(2026, 7, 8, 18, 0, 0) # 6:00 PM
        expect(service.within_business_hours?(time_late)).to be false
      end
    end

    it "returns false on a weekend" do
      Time.use_zone("UTC") do
        saturday = Time.zone.local(2026, 7, 11, 10, 0, 0)
        expect(service.within_business_hours?(saturday)).to be false
      end
    end

    it "returns false on a holiday" do
      create(:management_holiday, date: Date.new(2026, 7, 8), name: "Test Holiday", cooperative: cooperative)
      Time.use_zone("UTC") do
        time = Time.zone.local(2026, 7, 8, 10, 0, 0)
        expect(service.within_business_hours?(time)).to be false
      end
    end
  end

  describe "#after_cutoff?" do
    it "returns false before cutoff" do
      Time.use_zone("UTC") do
        time = Time.zone.local(2026, 7, 8, 8, 0, 0)
        expect(service.after_cutoff?(time)).to be false
      end
    end

    it "returns true after cutoff" do
      Time.use_zone("UTC") do
        time = Time.zone.local(2026, 7, 8, 17, 0, 0)
        expect(service.after_cutoff?(time)).to be true
      end
    end
  end

  describe "#next_business_day" do
    it "returns the next day for a weekday" do
      wednesday = Date.new(2026, 7, 8)
      expect(service.next_business_day(wednesday)).to eq(Date.new(2026, 7, 9))
    end

    it "skips Saturday" do
      friday = Date.new(2026, 7, 10)
      expect(service.next_business_day(friday)).to eq(Date.new(2026, 7, 13))
    end

    it "skips Sunday" do
      friday = Date.new(2026, 7, 11) # Saturday
      expect(service.next_business_day(friday)).to eq(Date.new(2026, 7, 13))
    end

    it "skips holidays" do
      create(:management_holiday, date: Date.new(2026, 7, 9), name: "Test Holiday", cooperative: cooperative)
      wednesday = Date.new(2026, 7, 8)
      expect(service.next_business_day(wednesday)).to eq(Date.new(2026, 7, 10))
    end
  end

  context "without cooperative" do
    subject(:service) { described_class.new }

    it "falls back to defaults" do
      expect(service.business_day?(Date.new(2026, 7, 8))).to be true
    end
  end
end
