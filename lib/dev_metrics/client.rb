require 'net/http'
require 'uri'
require 'date'
require 'json'
require 'time'
require_relative 'query_builder'
require_relative 'metrics_calc'

module DevMetrics
  class Client
    GITHUB_GRAPHQL_API = 'https://api.github.com/graphql'.freeze
    ACCESS_TOKEN = ENV.fetch('GITHUB_ACCESS_TOKEN', nil)

    def initialize(config)
      @repo_name = config.repo_name
      @bot_accounts = config.bot_accounts || []
      @access_token = config.access_token || ENV.fetch('GITHUB_ACCESS_TOKEN', nil)
      @fix_branch_names = config.fix_branch_names || %w(hotfix fix rollback)
    end

    def process(period: Date.today)
      uri = URI.parse(GITHUB_GRAPHQL_API)
      builder = DevMetrics::QueryBuilder.new(@repo_name)

      auth_request = build_request(uri, builder.access_auth_check)
      auth_response = execute_request(uri, auth_request)
      check_auth_errors!(auth_response)

      pr_request = build_request(uri, builder.pull_requests_for(period))
      pr_response = execute_request(uri, pr_request)

      pr_data = parse_response(pr_response)

      output_metrics(DevMetrics::MetricsCalc.new(pr_data, period, @bot_accounts, @fix_branch_names))
      puts "Done. Please check the file #{output_filename}"
    end

    private

    def build_request(uri, body)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@access_token}"
      request.body = body
      request
    end

    def execute_request(uri, request)
      options = { use_ssl: uri.scheme == 'https' }
      Net::HTTP.start(uri.hostname, uri.port, options) { |http| http.request(request) }
    end

    def check_auth_errors!(response)
      if response.code.to_i == 403 || response.body.include?('FORBIDDEN')
        raise "Access denied: ensure the access token has permission to access #{@repo_name}"
      end
    end

    def parse_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch data: #{response.message} (#{response.code})"
      end

      data = JSON.parse(response.body)
      raise "GraphQL error: #{data['errors']}" if data['errors']

      data.dig('data', 'search', 'edges') || []
    end

    def output_metrics(metrics_calc)
      raise NotImplementedError, "Subclasses must implement the method."
    end
  end
end
