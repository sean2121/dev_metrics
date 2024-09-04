require 'net/http'
require 'uri'
require 'date'
require 'json'
require 'time'
require 'pry'

module DevMetrics
  class Client
    GITHUB_GRAPHQL_API = 'https://api.github.com/graphql'.freeze
    ACCESS_TOKEN = ENV.fetch('GITHUB_ACCESS_TOKEN', nil)

    def initialize(config)
      @repo_name = config.repo_name
      @bot_accounts = config.bot_accounts || []
      @access_token = config.access_token || ENV.fetch('GITHUB_ACCESS_TOKEN', nil)
    end

    def process(period: Date.today)
      uri = URI.parse(GITHUB_GRAPHQL_API)
      request = build_request(uri, period)
      response = execute_request(uri, request)

      pr_data = parse_response(response)
      filtered_prs = exclude_bots(pr_data)
      correction_pr_count = count_correction_prs(filtered_prs)

      output_metrics(period, filtered_prs, correction_pr_count)
      puts "Done. Please check the file #{output_filename}"
    end

    private

    def build_request(uri, period)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@access_token}"
      request.body = graphql_query(period)

      request
    end

    def execute_request(uri, request)
      options = { use_ssl: uri.scheme == 'https' }
      Net::HTTP.start(uri.hostname, uri.port, options) { |http| http.request(request) }
    end

    def parse_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch data: #{response.message} (#{response.code})"
      end

      JSON.parse(response.body).dig('data', 'search', 'edges')
    end

    def exclude_bots(prs)
      return prs if @bot_accounts.empty?
      prs.reject { |pr| @bot_accounts.include?(pr.dig('node', 'author', 'login')) }
    end

    def count_correction_prs(prs)
      prs.count { |pr| pr.dig('node', 'headRefName')&.match?(/^hotfix|fix|rollback/) }
    end

    def calculate_lead_time(prs)
      return "0d 00:00:00" if prs.empty?

      times = prs.map do |pr|
        merged_at = Time.parse(pr.dig('node', 'mergedAt'))
        created_at = Time.parse(pr.dig('node', 'publishedAt'))
        merged_at - created_at
      end

      average_time = times.sum.fdiv(times.size)
      format_time(average_time)
    end

    def format_time(seconds)
      return "0d 00:00:00" if seconds.nan? || seconds.infinite?

      days, remaining = seconds.divmod(86_400)
      Time.at(remaining).utc.strftime("#{days}d %H:%M:%S")
    end

    def graphql_query(period)
      query_string = <<-GRAPHQL
    {
      search(query: "repo:#{@repo_name} is:pr merged:#{period}", type: ISSUE, first: 100) {
        edges {
          node {
            ... on PullRequest {
              url
              title
              author {
                login
              }
              mergedAt
              headRefName
              publishedAt
            }
          }
        }
      }
    }
      GRAPHQL
      { "query" => query_string.strip }.to_json
    end

    def output_metrics(period, prs, correction_pr_count)
      formatted_data = format_data(period, prs, correction_pr_count)

      File.open(output_filename, 'a') do |file|
        file.write(formatted_data)
      end
    end

    def format_data(period, prs, correction_pr_count)
      raise NotImplementedError, "This method must be implemented by subclasses."
    end

    def output_filename
      raise NotImplementedError, "This method must be implemented by subclasses."
    end
  end
end
