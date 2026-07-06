module Accounting
  class PostingEngine
    include IdempotentService

    attr_reader :template, :input, :actor, :entry

    def initialize(template:, input: {}, actor: nil)
      @template = template
      @input = input.with_indifferent_access
      @actor = actor
      @entry = nil
    end

    def preview
      TemplateResolver.new(@template, @input).resolve_lines
    end

    def post!(idempotency_key: nil)
      with_idempotency(key: idempotency_key) do
        Accounting::Entry.transaction do
          build_entry
          @entry.save!
          @template.update!(entry: @entry)
          Accounting::UpdateRunningBalances.run!(entry: @entry)
          @entry
        end
      end
    end

    private

    def build_entry
      resolver = TemplateResolver.new(@template, @input)

      accounts = resolver.resolve_debits.map { |l| l[:account] } + resolver.resolve_credits.map { |l| l[:account] }
      accounts.each do |account|
        AccountStatusService.new(account: account).can_post!
      end

      @entry = Accounting::Entry.build(
        description: build_description,
        posted_at: Time.current,
        debits: resolver.resolve_debits.map { |l| { account: l[:account], amount: l[:amount_cents] } },
        credits: resolver.resolve_credits.map { |l| { account: l[:account], amount: l[:amount_cents] } }
      )
    end

    def build_description
      "#{@template.name} — #{Time.current.strftime("%b %d, %Y %H:%M")}"
    end
  end
end
