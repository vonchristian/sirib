module Management
  class ConfigurationsController < BaseController
    before_action :set_configuration, only: [:show, :edit, :update, :approve, :activate]

    def index
      @pagy, @configurations = pagy(Management::Configuration.order(:key))
    end

    def show
      @versions = @configuration.versions.limit(10)
    end

    def new
      @configuration = Management::Configuration.new
    end

    def create
      @configuration = Management::Configuration.new(configuration_params)
      @configuration.changed_by = Current.user
      if @configuration.save
        redirect_to management_configuration_path(@configuration), notice: "Configuration was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @configuration.update(configuration_params)
        @configuration.update!(changed_by: Current.user)
        redirect_to management_configuration_path(@configuration), notice: "Configuration was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      @configuration.update!(status: :active, approved_by: Current.user, approved_at: Time.current)
      redirect_to management_configuration_path(@configuration), notice: "Configuration was approved and activated."
    end

    def activate
      @configuration.update!(status: :active)
      redirect_to management_configuration_path(@configuration), notice: "Configuration was activated."
    end

    private

    def set_configuration
      @configuration = Management::Configuration.find(params[:id])
    end

    def configuration_params
      params.require(:management_configuration).permit(:key, :value, :configurable_type, :configurable_id)
    end
  end
end
