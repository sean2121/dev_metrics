require 'yaml'

module DevMetrics
  class FormatBase

    attr_reader :metrics_calc

    def initialize(metrics_calc, config_path = "dev_metrics_config.yml")
      @metrics_calc = metrics_calc
      @format_config = YAML.load_file(config_path)
    end

    private

    def write; end

    def file_name; end

    def columns
      @format_config['columns'] || []
    end

    def build_row
      columns.map do |column|
        key = column['key'] || column
        begin
          value = @metrics_calc.send(key)
        rescue NoMethodError
          value = "No defined for #{key}"
        end
        value
      end
    end
  end
end
