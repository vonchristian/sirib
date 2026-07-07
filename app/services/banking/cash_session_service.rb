module Banking
  class CashSessionService
    Result = Struct.new(:success?, :cash_session, :errors, keyword_init: true) do
      def valid? = success?
    end

    def self.open(user:, cash_account: nil)
      new.open(user:, cash_account:)
    end

    def self.close(cash_session:, ending_balance: nil, notes: nil)
      new.close(cash_session:, ending_balance:, notes:)
    end

    def open(user:, cash_account: nil)
      existing = user.current_cash_session
      return Result.new(success?: true, cash_session: existing) if existing&.open?
      return Result.new(success?: false, errors: [ "Existing session must be closed first" ]) if existing&.open?

      unless Management::BusinessDayService.new(cooperative: user.cooperative).within_business_hours?
        return Result.new(success?: false, errors: [ "Cash sessions can only be opened during business hours" ])
      end

      cash_account ||= user.cash_accounts.includes(:account).first&.account
      return Result.new(success?: false, errors: [ "No cash account assigned" ]) unless cash_account

      session = Treasury::CashSession.create!(
        user: user,
        cash_account: cash_account,
        date: Date.current,
        opened_at: Time.current,
        status: "open",
        beginning_balance_cents: cash_account.balance.cents
      )

      broadcast_session_update(session)
      Result.new(success?: true, cash_session: session)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    def close(cash_session:, ending_balance: nil, notes: nil)
      return Result.new(success?: false, errors: [ "Session is already closed" ]) if cash_session.closed?

      cash_session.update!(
        status: "closed",
        closed_at: Time.current,
        ending_balance_cents: ending_balance || cash_session.computed_ending_balance,
        notes: notes
      )

      broadcast_session_update(cash_session)
      Result.new(success?: true, cash_session: cash_session)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, errors: [ e.message ])
    end

    private

    def broadcast_session_update(session)
      Turbo::StreamsChannel.broadcast_replace_to(
        "shell_cash_session",
        target: "cash_session_status",
        partial: "shell/cash_sessions/status",
        locals: { cash_session: session }
      )
    rescue StandardError
      nil
    end
  end
end
