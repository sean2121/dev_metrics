require_relative 'format_base'

module DevMetrics
  class Markdown < FormatBase

    def call
      write
    end

    private

    def write
      is_new_file = !File.exist?(file_name) || File.size(file_name).zero?
      File.open(file_name, "a") do |file|
        if is_new_file
          file.puts "| " + columns.map { |col| col['label'] || col }.join(' | ') + " |"
          file.puts "| " + (["---"] * columns.size).join(' | ') + " |"
        end
        file.puts "| " + build_row.join(' | ') + " |"
      end
    end

    def file_name
      "dev_metrics.md"
    end
  end
end
