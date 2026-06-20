module External
  class EntryTemplatesController < BaseController
    before_action { set_active_nav }
    before_action :set_bank
    before_action :set_account

    def create
      @template = Accounting::EntryTemplate.new(
        name: "Interest Earned — #{@account.account_name}",
        lines_attributes: {
          "0" => { account_id: @account.cash_on_hand_account_id, direction: "debit", amount_mode: "variable", sequence_index: 1 },
          "1" => { account_id: @account.interest_income_account_id, direction: "credit", amount_mode: "variable", sequence_index: 2 }
        }
      )

      if @template.save
        redirect_to management_entry_template_path(@template), notice: "Interest Earned template created. Enter amount and post."
      else
        redirect_to external_bank_account_path(@bank, @account), alert: @template.errors.full_messages.to_sentence
      end
    end

    private

    def set_bank
      @bank = External::Bank.find(params[:bank_id])
    end

    def set_account
      @account = @bank.accounts.find(params[:account_id])
    end
  end
end
