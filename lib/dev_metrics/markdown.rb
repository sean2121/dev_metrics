require_relative 'client'

module DevMetrics
  class Markdown < FormartBase

    private

    def data_format(metrics_calc)
      output = ""

      output << "| #{metrics_calc.period} | #{metrics_calc.prs_length} | #{metrics_calc.rollback_prs_length} | "
      output << "#{metrics_calc.failure_rate}% | "
      output << "#{metrics_calc.lead_time} | "
      output << "#{metrics_calc.average_changed_line_size} |"
      output << "#{metrics_calc.average_changed_file} | "
      output << "[PRs for #{metrics_calc.period}](https://github.com/#{@repo_name}/pulls?q=is%3Apr+merged%3A#{metrics_calc.period}) |\n"
      output
    end

    def write(metrics_calc)
      formatted_data = data_format(metrics_calc)

      File.open(output_filename, 'a') do |file|
        file.write(formatted_data)
      end
    end


    def output_filename
      "metrics_report.md"
    end
  end
end
