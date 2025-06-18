module DevMetrics
  class QueryBuilder

    def initialize(repo)
      @repo = repo
    end

    def access_auth_check
      to_body <<~GRAPHQL
      {
         repository(owner: "#{@repo.split('/')[0]}", name: "#{@repo.split('/')[1]}"){
          id
        }
      }
      GRAPHQL
    end

    def pull_requests_for(period)
      to_body <<~GRAPHQL
      {
        search(query: "repo:#{@repo} is:pr merged:#{period}", type: ISSUE, first: 100) {
          edges {
            node {
              ... on PullRequest {
                url
                number
                title
                body
                state
                createdAt
                updatedAt
                closedAt
                mergedAt
                author { login }
                assignees(first: 10) { nodes { login } }
                labels(first: 10) { nodes { name } }
                headRefName
                baseRefName
                additions
                deletions
                changedFiles
                commits { totalCount }
                reviews { totalCount }
                reviewRequests { totalCount }
                mergedBy { login }
                milestone { title }
                isDraft
                mergeable
              }
            }
          }
        }
      }
      GRAPHQL
    end

    private

    def to_body(query_string)
      { "query" => query_string.strip }.to_json
    end
  end
end
