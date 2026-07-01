module External
  class BanksController < BaseController
    before_action { set_active_nav }
    before_action :set_bank, only: [ :show, :edit, :update, :destroy ]

    def index
      @banks = External::Bank.all
      @banks = @banks.active if params[:status] == "active"
    end

    def new
      @bank = External::Bank.new
    end

    def create
      @bank = External::Bank.new(bank_params)

      if @bank.save
        redirect_to external_bank_path(@bank), notice: "Bank was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @accounts = @bank.accounts.order(created_at: :desc)
    end

    def edit
    end

    def update
      if @bank.update(bank_params)
        redirect_to external_bank_path(@bank), notice: "Bank was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bank.update!(status: :inactive)

      redirect_to external_banks_path, notice: "Bank was successfully deactivated."
    end

    private

    def set_bank
      @bank = External::Bank.find(params[:id])
    end

    def bank_params
      params.require(:external_bank).permit(:name, :code, :country, :status)
    end
  end
end
