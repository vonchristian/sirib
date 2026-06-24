module Lending
  class ScheduleVersioningService
    def self.call(loan:, new_schedule_data:, supersede_existing: true)
      new(loan, new_schedule_data, supersede_existing).call
    end

    def initialize(loan, new_schedule_data, supersede_existing)
      @loan = loan
      @new_schedule_data = new_schedule_data
      @supersede_existing = supersede_existing
    end

    def call
      Lending::LoanSchedule.transaction do
        supersede_active_schedule if @supersede_existing

        next_version = (@loan.loan_schedules.maximum(:version) || 0) + 1

        Lending::LoanSchedule.create!(
          cooperative: @loan.cooperative,
          loan: @loan,
          version: next_version,
          status: "active",
          schedule_data: @new_schedule_data
        )
      end
    end

    private

    def supersede_active_schedule
      @loan.loan_schedules.active.find_each do |schedule|
        schedule.update!(status: "superseded", superseded_at: Time.current)
      end
    end
  end
end
