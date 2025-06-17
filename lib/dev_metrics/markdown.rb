require_relative 'format_base'

module DevMetrics
  class Markdown < FormatBase

    def call
      write
    end

    private

    def write
      File.open(file_name, "w") do |file|
        file.puts "| " + columns.map { |col| col['label'] || col }.join(' | ') + " |"
        file.puts "| " + (["---"] * columns.size).join(' | ') + " |"
        file.puts "| " + build_row.join(' | ') + " |"
      end
    end

    def file_name
      "output.md"
    end
  end
end
