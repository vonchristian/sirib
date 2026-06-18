module Treasury
  class VaultTransferService
    Result = Struct.new(:success?, :transfer, :errors, keyword_init: true)

    def self.request_to_teller(cash_session:, amount_cents:, description: nil)
      new.request(cash_session:, direction: :to_teller, amount_cents:, description:)
    end

    def self.request_to_vault(cash_session:, amount_cents:, description: nil)
      new.request(cash_session:, direction: :to_vault, amount_cents:, description:)
    end

    def request(cash_session:, direction:, amount_cents:, description: nil)
      return Result.new(success?: false, errors: ["Amount must be positive"]) if amount_cents.to_i <= 0
      return Result.new(success?: false, errors: ["Session is closed"]) if cash_session.closed?

      transfer = cash_session.vault_transfers.new(
        direction: direction,
        amount_cents: amount_cents,
        description: description.presence,
        status: :pending
      )

      if transfer.save
        Result.new(success?: true, transfer:)
      else
        Result.new(success?: false, errors: transfer.errors.full_messages)
      end
    end

    def self.approve(transfer, approver:)
      transfer.approve!(approver: approver)
      Result.new(success?: true, transfer:)
    rescue => e
      Result.new(success?: false, errors: [e.message])
    end

    def self.reject(transfer, approver:)
      transfer.reject!(approver: approver)
      Result.new(success?: true, transfer:)
    rescue => e
      Result.new(success?: false, errors: [e.message])
    end
  end
end
