module Management
  class BusinessDayService
    DEFAULT_OPEN_HOUR = 8
    DEFAULT_CLOSE_HOUR = 17
    DEFAULT_CUTOFF_HOUR = 17

    def initialize(cooperative: nil)
      @cooperative = cooperative
    end

    def business_day?(date = Date.current)
      !date.saturday? && !date.sunday? && !holiday?(date)
    end

    def within_business_hours?(time = Time.current)
      business_day?(time.to_date) && time.hour >= open_hour && time.hour < close_hour
    end

    def after_cutoff?(time = Time.current)
      time.hour >= cutoff_hour
    end

    def next_business_day(from_date = Date.current)
      date = from_date + 1.day
      date += 1.day while !business_day?(date)
      date
    end

    private

    def open_hour
      config_value("business_hours_open", DEFAULT_OPEN_HOUR).to_i
    end

    def close_hour
      config_value("business_hours_close", DEFAULT_CLOSE_HOUR).to_i
    end

    def cutoff_hour
      config_value("business_hours_cutoff", DEFAULT_CUTOFF_HOUR).to_i
    end

    def holiday?(date)
      return false unless @cooperative

      Management::Holiday.holiday?(date, cooperative: @cooperative)
    end

    def config_value(key, default)
      return default unless @cooperative

      config = Management::Configuration.find_by(cooperative: @cooperative, key: key)
      config&.value.is_a?(Hash) ? config.value["value"] : default
    end
  end
end
