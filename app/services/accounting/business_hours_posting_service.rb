module Accounting
  class BusinessHoursPostingService
    def self.post(cooperative:, description:, reference_number: nil, posted_at: nil,
                  debits: [], credits: [], post_immediately: nil)
      new.post(cooperative:, description:, reference_number:, posted_at:,
               debits:, credits:, post_immediately:)
    end

    def post(cooperative:, description:, reference_number: nil, posted_at: nil,
             debits: [], credits: [], post_immediately: nil)
      actually_post = if post_immediately == true
                        true
      elsif post_immediately == false
                        false
      else
                        Management::BusinessDayService.new(cooperative:).within_business_hours?
      end

      Accounting::PostEntryService.run!(
        description:,
        reference_number:,
        posted_at: posted_at || Time.current,
        cooperative:,
        post_immediately: actually_post,
        debits:,
        credits:
      )
    end
  end
end
