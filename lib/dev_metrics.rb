require_relative 'dev_metrics/markdown'
require_relative 'dev_metrics/version'
require_relative 'dev_metrics/client'
require_relative 'dev_metrics/metrics_calc'

module DevMetrics
  class Config
    attr_accessor :access_token, :repo_name, :bot_accounts, :fix_branch_names

    def initialize
      @access_token = nil
      @repo_name = nil
      @bot_accounts = nil
      @fix_branch_names = nil
    end
  end

  @configuration = Config.new

  def self.configuration
    @configuration
  end

  def self.configure
    yield(configuration)
  end

  # Run: fetch PRs, calculate metrics, and pass to formatter
  def self.run(period:, format:)
    client = DevMetrics::Client.new(@configuration)
    prs = client.fetch(period)

    format.new(prs)
  end
end
