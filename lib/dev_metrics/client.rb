require 'net/http'
require 'uri'
require 'date'
require 'json'
require 'time'
require_relative 'query_builder'
require_relative 'metrics_calc'
require_relative 'pull_request_wrapper'


module DevMetrics
  class Client
    GITHUB_GRAPHQL_API = 'https://api.github.com/graphql'.freeze

    def initialize(config)
      @repo_name = config.repo_name
      @access_token = config.access_token
      @bot_accounts = config.bot_accounts || []
      @fix_branch_names = config.fix_branch_names || %w(hotfix fix rollback)
    end

    def fetch(period: Date.today)
      uri = URI.parse(GITHUB_GRAPHQL_API)
      builder = DevMetrics::QueryBuilder.new(@repo_name)


      token = @access_token

      auth_request = build_request(uri, builder.access_auth_check, token)
      auth_response = execute_request(uri, auth_request)
      check_auth_errors!(auth_response)

      pr_request = build_request(uri, builder.pull_requests_for(period), token)
      pr_response = execute_request(uri, pr_request)

      pr_data = parse_response(pr_response)
      parsed_pr_data = pr_data.map { |row| DevMetrics::PullRequestWrapper.new(row) }

      DevMetrics::MetricsCalc.new(
        parsed_pr_data,
        period,
        bot_accounts: @bot_accounts,
        fix_branch_names: @fix_branch_names
      )
    end

    private

    def build_request(uri, body, token)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{token}"
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
  end
end
