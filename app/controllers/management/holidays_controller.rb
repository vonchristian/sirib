module Management
  class HolidaysController < BaseController
    before_action :set_holiday, only: [ :show, :edit, :update, :destroy ]

    def index
      @pagy, @holidays = pagy(Management::Holiday.order(date: :desc))
    end

    def show
    end

    def new
      @holiday = Management::Holiday.new
    end

    def create
      @holiday = Management::Holiday.new(holiday_params)
      if @holiday.save
        redirect_to management_holiday_path(@holiday), notice: "Holiday was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @holiday.update(holiday_params)
        redirect_to management_holiday_path(@holiday), notice: "Holiday was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @holiday.destroy
      redirect_to management_holidays_path, notice: "Holiday was successfully deleted."
    end

    private

    def set_holiday
      @holiday = Management::Holiday.find(params[:id])
    end

    def holiday_params
      params.require(:management_holiday).permit(:date, :name, :recurring)
    end
  end
end
