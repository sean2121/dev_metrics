module DevMetrics
  class MetricsCalc
    attr_reader :period

    def initialize(prs, period, bot_accounts:, fix_branch_names:)
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
      @prs.count { |pr| pr.head_ref_name&.match?(/^#{@fix_branch_names.join('|')}/) }
    end

    # Returns the average lead time for PRs (from creation to merge) as a formatted string.
    #
    # @return [String] Average lead time formatted as "Xd HH:MM:SS".
    def lead_time
      return "0d 00:00:00" if @prs.empty?

      times = @prs.map do |pr|
        merged_at = pr.merged_at
        created_at = pr.created_at
        merged_at && created_at ? merged_at - created_at : 0
      end

      average_time = times.sum.fdiv(times.size)
      format_time(average_time)
    end

    # Returns the failure rate (percentage of rollback PRs).
    #
    # @return [String, Float] Percentage of rollback PRs or "-" if no PRs.
    def failure_rate
      return "-" if @prs.empty?
      ((rollback_prs_length.to_f / @prs.count) * 100).round(2)
    end

    # Returns the average PR size (additions + deletions).
    #
    # @return [Float] Average PR size.
    def average_changed_line_size
      return 0 if @prs.empty?
      sizes = @prs.map { |pr| pr.additions + pr.deletions }
      (sizes.sum.to_f / sizes.size).round(2)
    end

    # Returns the average number of changed files per PR.
    #
    # @return [Float] Average number of changed files.
    def average_changed_file
      return 0 if @prs.empty?
      files = @prs.map(&:changed_files)
      (files.sum.to_f / files.size).round(2)
    end

    # Returns the maximum PR size (additions + deletions).
    #
    # @return [Integer] Maximum PR size.
    def max_pr_size
      return 0 if @prs.empty?
      @prs.map { |pr| pr.additions + pr.deletions }.max
    end

    # Returns the minimum PR size (additions + deletions).
    #
    # @return [Integer] Minimum PR size.
    def min_pr_size
      return 0 if @prs.empty?
      @prs.map { |pr| pr.additions + pr.deletions }.min
    end

    # Returns the average number of commits per PR.
    #
    # @return [Float] Average number of commits.
    def average_commits_count
      return 0 if @prs.empty?
      counts = @prs.map(&:commits_count)
      (counts.sum.to_f / counts.size).round(2)
    end

    # Returns the average number of reviews per PR.
    #
    # @return [Float] Average number of reviews.
    def average_reviews_count
      return 0 if @prs.empty?
      counts = @prs.map(&:reviews_count)
      (counts.sum.to_f / counts.size).round(2)
    end

    # Returns the average number of review requests per PR.
    #
    # @return [Float] Average number of review requests.
    def average_review_requests_count
      return 0 if @prs.empty?
      counts = @prs.map(&:review_requests_count)
      (counts.sum.to_f / counts.size).round(2)
    end

    # Returns the percentage of PRs that are drafts.
    #
    # @return [Float] Percentage of draft PRs.
    def draft_pr_rate
      return 0 if @prs.empty?
      draft_count = @prs.count(&:draft?)
      ((draft_count.to_f / @prs.size) * 100).round(2)
    end

    # Returns a hash with label names as keys and their counts as values.
    #
    # @return [Hash] Label counts.
    def label_counts
      @prs.flat_map(&:labels).compact.tally
    end

    # Returns a hash with assignee names as keys and their counts as values.
    #
    # @return [Hash] Assignee counts.
    def assignee_counts
      @prs.flat_map(&:assignees).compact.tally
    end

    # Returns a hash with milestone titles as keys and their counts as values.
    #
    # @return [Hash] Milestone counts.
    def milestone_counts
      @prs.map(&:milestone).compact.tally
    end

    # Returns the average PR age in days (from creation to close, or now if open).
    #
    # @return [Float] Average PR age in days.
    def average_pr_age
      return 0 if @prs.empty?
      ages = @prs.map do |pr|
        closed = pr.closed_at || Time.now
        created = pr.created_at
        created && closed ? (closed - created) / 86400.0 : 0
      end
      (ages.sum / ages.size).round(2)
    end

    # Returns the maximum PR age in days.
    #
    # @return [Float] Maximum PR age in days.
    def max_pr_age
      return 0 if @prs.empty?
      ages = @prs.map do |pr|
        closed = pr.closed_at || Time.now
        created = pr.created_at
        created && closed ? (closed - created) / 86400.0 : 0
      end
      ages.max.round(2)
    end

    # Returns the minimum PR age in days.
    #
    # @return [Float] Minimum PR age in days.
    def min_pr_age
      return 0 if @prs.empty?
      ages = @prs.map do |pr|
        closed = pr.closed_at || Time.now
        created = pr.created_at
        created && closed ? (closed - created) / 86400.0 : 0
      end
      ages.min.round(2)
    end

    # Returns the number of draft PRs.
    #
    # @return [Integer] Number of draft PRs.
    def draft_pr_count
      @prs.count(&:draft?)
    end

    # Returns the number of merged PRs.
    #
    # @return [Integer] Number of merged PRs.
    def merged_pr_count
      @prs.count { |pr| !pr.merged_at.nil? }
    end

    # Returns the number of closed but unmerged PRs.
    #
    # @return [Integer] Number of closed but unmerged PRs.
    def closed_unmerged_pr_count
      @prs.count { |pr| pr.closed_at && pr.merged_at.nil? }
    end

    private

    def count_prs_with_excluded_account(prs, bot_accounts)
      return prs if bot_accounts.empty?
      prs.reject { |pr| bot_accounts.include?(pr.author) }
    end

    def format_time(seconds)
      return "0d 00:00:00" if seconds.nan? || seconds.infinite?
      days, remaining = seconds.divmod(86_400)
      Time.at(remaining).utc.strftime("#{days}d %H:%M:%S")
    end
  end
end
