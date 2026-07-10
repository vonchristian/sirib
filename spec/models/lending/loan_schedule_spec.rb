require "rails_helper"

RSpec.describe Lending::LoanSchedule do
  describe "associations" do
    it { is_expected.to belong_to(:loan) }
    it { is_expected.to belong_to(:cooperative) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_numericality_of(:version).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active superseded]) }
  end

  describe "scopes" do
    let!(:active_schedule) { create(:lending_loan_schedule, status: "active") }
    let!(:superseded_schedule) { create(:lending_loan_schedule, status: "superseded") }

    it "returns active schedules" do
      expect(Lending::LoanSchedule.active).to contain_exactly(active_schedule)
    end

    it "returns superseded schedules" do
      expect(Lending::LoanSchedule.superseded).to contain_exactly(superseded_schedule)
    end
  end

  describe "#active?" do
    it "returns true when status is active" do
      schedule = build(:lending_loan_schedule, status: "active")
      expect(schedule).to be_active
    end

    it "returns false when status is superseded" do
      schedule = build(:lending_loan_schedule, status: "superseded")
      expect(schedule).not_to be_active
    end
  end

  describe "#superseded?" do
    it "returns true when status is superseded" do
      schedule = build(:lending_loan_schedule, status: "superseded")
      expect(schedule).to be_superseded
    end

    it "returns false when status is active" do
      schedule = build(:lending_loan_schedule, status: "active")
      expect(schedule).not_to be_superseded
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:lending_loan_schedule)).to be_valid
    end
  end

  describe "optimistic locking" do
    it_behaves_like "an optimistically locked model" do
      let(:factory) { :lending_loan_schedule }
      let(:update_attrs) { { status: "superseded" } }
    end
  end
end
