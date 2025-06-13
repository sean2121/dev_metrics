require_relative 'formatter_helper'

module DevMetrics
  class MetricsCalc
    attr_reader :period

    def initialize(prs, period, bot_accounts, fix_branch_names)
      @prs = prs
      @period = period
      @bot_accounts = bot_accounts || []
      @fix_branch_names = fix_branch_names
    end

    # Returns the number of PRs excluding those created by bot accounts.
    #
    # @return [Integer] Number of PRs excluding bots.
    def prs_length
      count_prs_with_excluded_account(@prs, @bot_accounts).length
    end

    # Returns the number of rollback PRs (branch name matches fix patterns).
    #
    # @return [Integer] Number of rollback PRs.
    def rollback_prs_length
      @prs.count { |pr| pr.dig('node', 'headRefName')&.match?(/^#{@fix_branch_names.join('|')}/) }
    end

    # Calculates the average lead time for PRs (from creation to merge).
    #
    # @return [String] Average lead time formatted as "Xd HH:MM:SS".
    def lead_time
      return "0d 00:00:00" if @prs.empty?

      times = @prs.map do |pr|
        merged_at = Time.parse(pr.dig('node', 'mergedAt'))
        created_at = Time.parse(pr.dig('node', 'publishedAt'))
        merged_at - created_at
      end

      average_time = times.sum.fdiv(times.size)
      format_time(average_time)
    end

    # Calculates the failure rate (percentage of rollback PRs).
    #
    # @return [String, Float] Percentage of rollback PRs or "-" if no PRs.
    def failure_rate
      return "-" if @prs.empty?
      ((rollback_prs_length.to_f / @prs.count) * 100).round(2)
    end

    # Calculates the average PR size (additions + deletions).
    #
    # @return [Float] Average PR size.
    def average_changed_line_size
      return 0 if @prs.empty?
      sizes = @prs.map do |pr|
        node = pr['node']
        (node['additions'] || 0) + (node['deletions'] || 0)
      end
      (sizes.sum.to_f / sizes.size).round(2)
    end

    # Calculates the average number of changed files per PR.
    #
    # @return [Float] Average number of changed files.
    def average_changed_file
      return 0 if @prs.empty?
      files = @prs.map { |pr| pr.dig('node', 'changedFiles').to_i }
      (files.sum.to_f / files.size).round(2)
    end

    # Returns the maximum PR size (additions + deletions).
    #
    # @return [Integer] Maximum PR size.
    def max_pr_size
      return 0 if @prs.empty?
      @prs.map { |pr| (pr['node']['additions'] || 0) + (pr['node']['deletions'] || 0) }.max
    end

    # Returns the minimum PR size (additions + deletions).
    #
    # @return [Integer] Minimum PR size.
    def min_pr_size
      return 0 if @prs.empty?
      @prs.map { |pr| (pr['node']['additions'] || 0) + (pr['node']['deletions'] || 0) }.min
    end

    private

    # Excludes PRs created by bot accounts.
    #
    # @param [Array<Hash>] prs Array of pull request data.
    # @param [Array<String>, nil] bot_accounts Array of bot account names.
    # @return [Array<Hash>] PRs excluding those by bot accounts.
    def count_prs_with_excluded_account(prs, bot_accounts)
      return prs if bot_accounts.empty?
      prs.reject { |pr| bot_accounts.include?(pr.dig('node', 'author', 'login')) }
    end

    def format_time(seconds)
      return "0d 00:00:00" if seconds.nan? || seconds.infinite?
      days, remaining = seconds.divmod(86_400)
      Time.at(remaining).utc.strftime("#{days}d %H:%M:%S")
    end
  end
end
