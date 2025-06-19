require 'optparse'
require 'yaml'
require_relative 'dev_metrics/markdown'
require_relative 'dev_metrics/version'
require_relative 'dev_metrics/client'
require_relative 'dev_metrics/metrics_calc'
require_relative 'dev_metrics/csv'
require_relative 'dev_metrics/json'


module DevMetrics
  class Config
    attr_accessor :access_token, :repo_name, :excluded_accounts, :rollback_branch_prefixes

    def initialize
      @access_token = nil
      @repo_name = nil
      @excluded_accounts = []
      @rollback_branch_prefixes = []
    end

    def load_from_yaml(path = "dev_metrics_config.yml")
      unless File.exist?(path)
        warn "Config file '#{path}' not found. Please create it before running this tool."
        exit 1
      end

      config = YAML.load_file(path)
      if config["access_token"].nil? || config["repo_name"].nil?
        warn "Config file must include 'access_token' and 'repo_name'."
        exit 1
      end

      @access_token = config["access_token"]
      @repo_name = config["repo_name"]
      @excluded_accounts = config["excluded_accounts"] || []
      @rollback_branch_prefixes = config["rollback_branch_prefixes"] || []
    end
  end

  @configuration = Config.new

  def self.configuration
    @configuration
  end

  def self.option_parse(argv)
    options = {
      period: (Date.today << 1).strftime("%Y-%m"),
      format: "csv",
      config: "dev_metrics_config.yml"
    }
    OptionParser.new do |opts|
      opts.banner = "Usage: dev_metrics [options]"

      opts.on("-c", "--config FILE", "Specify config YAML file (default: dev_metrics_config.yml)") do |file|
        options[:config] = file
      end

      opts.on("-p", "--period PERIOD", "Specify the period for metrics (e.g., '2025-05' or '2025-05-01..2025-05-31')") do |period|
        options[:period] = period
      end

      opts.on("-f", "--format FORMAT", "Specify the output format (e.g., 'csv', 'json', 'markdown')") do |format|
        options[:format] = format
      end

      opts.on("-h", "--help", "Display this help message") do
        puts opts
        exit
      end
    end.parse!(argv)
    options
  end

  def self.run(argv: nil)
    argv ||= ARGV
    options = option_parse(argv)
    config_file = options[:config] || "dev_metrics_config.yml"
    @configuration.load_from_yaml(config_file)
    period = options[:period]
    format = options[:format]

    client = DevMetrics::Client.new(@configuration)
    prs = client.fetch(period: period)

    case format
    when "csv"
      DevMetrics::Csv.new(prs).call
    when "markdown"
      DevMetrics::Markdown.new(prs).call
    when "json"
      DevMetrics::Json.new(prs).call
    else
      warn "Unknown format: #{format}"
      warn "Available formats: csv, markdown, json"
      exit 1
    end
  end
end
