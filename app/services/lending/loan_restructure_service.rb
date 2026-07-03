module Lending
  class LoanRestructureService
    include IdempotentService
    STRATEGIES = {
      "modification" => "Lending::ModificationRestructure",
      "refinance" => "Lending::RefinanceRestructure",
      "hybrid" => "Lending::HybridRestructure"
    }.freeze

    def self.call(type:, loan:, proposed_changes:, requested_by: nil, **options)
      new(type, loan, proposed_changes, requested_by, options).call
    end

    def initialize(type, loan, proposed_changes, requested_by, options)
      @type = type
      @loan = loan
      @proposed_changes = proposed_changes.to_h.with_indifferent_access rescue proposed_changes
      @requested_by = requested_by || Current.user
      @options = options
    end

    def call
      with_idempotency(key: @options[:idempotency_key]) do
        validate_loan!
        validate_restructure_limit!

        restructure_case = create_restructure_case

        Lending::LoanEvent.create!(
          cooperative: @loan.cooperative,
          loan: @loan,
          actor: @requested_by || User.first,
          event_type: "restructure_requested",
          metadata: {
            restructure_type: @type,
            restructure_case_id: restructure_case.id,
            proposed_changes: @proposed_changes
          }
        )

        restructure_case
      end
    end

    def simulate
      validate_loan!

      strategy_class.constantize.new(@loan, @proposed_changes, @options).simulate
    end

    def execute(restructure_case:)
      raise "Case not approved" unless restructure_case.approved?
      raise "Case type mismatch" unless restructure_case.restructure_type == @type

      ActiveRecord::Base.transaction do
        result = strategy_class.constantize.new(@loan, @proposed_changes, @options).execute!

        restructure_case.execute!

        Lending::LoanEvent.create!(
          cooperative: @loan.cooperative,
          loan: @loan,
          actor: @requested_by || User.first,
          event_type: "#{@type}_completed",
          metadata: {
            restructure_case_id: restructure_case.id,
            result: result
          }
        )

        @loan.increment_restructures!

        result
      end
    end

    private

    def strategy_class
      STRATEGIES[@type] || raise("Unknown restructure type: #{@type}")
    end

    def validate_loan!
      raise "Loan cannot be restructured" unless @loan.restructurable?
    end

    def validate_restructure_limit!
      if @loan.restructures_count >= @loan.max_restructures
        raise "Maximum restructures (#{@loan.max_restructures}) reached for this loan"
      end
    end

    def create_restructure_case
      Lending::LoanRestructureCase.create!(
        cooperative: @loan.cooperative,
        loan: @loan,
        restructure_type: @type,
        status: "draft",
        proposed_changes: @proposed_changes,
        notes: @options[:notes],
        requested_by: @requested_by
      )
    end
  end
end
