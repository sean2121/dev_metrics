require_relative 'client'

module DevMetrics
  class Markdown < Client

    private

    def format_data(period, prs, correction_pr_count)
      output = ""
      output << "| #{period} | #{prs.count} | #{correction_pr_count} | "
      output << "#{correction_calc(correction_pr_count, prs)}% | "
      output << "#{calculate_lead_time(prs)} | "
      output << "[PRs for #{period}](https://github.com/#{@repo_name}/pulls?q=is%3Apr+merged%3A#{period}) |\n"
      output
    end

    def correction_calc(correction_pr_count, prs)
      return "-" if prs.empty?
      ((correction_pr_count.to_f / prs.count) * 100).round(2)
    end
    def output_filename
      "metrics_report.md"
    end
  end
end