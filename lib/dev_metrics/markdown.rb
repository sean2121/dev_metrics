require_relative 'format_base'

module DevMetrics
  class Markdown < FormatBase

    private

    def data_format
      output = ""

      output << "| #{metrics_calc.period} |"
      output << " #{metrics_calc.prs_length} |"
      output << " #{metrics_calc.rollback_prs_length} |"
      output << " #{metrics_calc.failure_rate}% |"
      output << " #{metrics_calc.lead_time} |"
      output << " #{metrics_calc.average_changed_line_size} |"
      output << " #{metrics_calc.average_changed_file} |"
      output << " [PRs for #{metrics_calc.period}](https://github.com/#{@repo_name}/pulls?q=is%3Apr+merged%3A#{metrics_calc.period}) |\n"
      output
    end

    def write
      formatted_data = data_format
      File.open(output_filename, 'a') do |file|
        file.write(formatted_data)
      end
    end


    def output_filename
      "metrics_report.md"
    end
  end
end
