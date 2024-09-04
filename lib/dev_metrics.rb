require_relative 'dev_metrics/markdown'

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

  def self.run(period:, format:)
    markdown_processor = format.new(@configuration)
    markdown_processor.process(period: period)
  end
end
