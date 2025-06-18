require_relative 'format_base'

module DevMetrics
  class Csv < FormatBase

    def call
      write
    end

    def file_name
      "dev_metrics.csv"
    end

    def format
      columns.map { |col| col['label'] || col }.join(',') + "\n" +
        build_row.join(',')
    end

    def write
      File.open(file_name, 'w') do |f|
        f.puts columns.map { |col| col['label'] || col }.join(',')
        f.puts build_row.join(',')
      end
      puts "CSV data written to #{file_name}"
    end
  end
end
