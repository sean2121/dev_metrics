module DevMetrics
  class FormatBase

    attr_reader :metrics_calc

    def initialize(metrics_calc)
      @metrics_calc = metrics_calc
      write
    end

    private

    def data_format
      raise NotImplementedError, "You must implement the data_format method in a subclass"
    end

    def output_filename
      raise NotImplementedError, "You must implement the output_filename method in a subclass"
    end

    def write
     raise NotImplementedError, "You must implement the write method in a subclass"
    end
  end
end
