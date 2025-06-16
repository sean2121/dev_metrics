module DevMetrics
  class PullRequestWrapper

    def initialize(row)
      @raw = row['node']
    end

    def url
      @raw['url']
    end

    def number
      @raw['number']
    end

    def title
      @raw['title']
    end

    def body
      @raw['body']
    end

    def state
      @raw['state']
    end

    def created_at
      Time.parse(@raw['createdAt'] || @raw['publishedAt']) rescue nil
    end

    def updated_at
      Time.parse(@raw['updatedAt']) rescue nil
    end

    def closed_at
      Time.parse(@raw['closedAt']) rescue nil
    end

    def merged_at
      Time.parse(@raw['mergedAt']) rescue nil
    end

    def published_at
      Time.parse(@raw['publishedAt']) rescue nil
    end

    def author
      @raw.dig('author', 'login')
    end

    def assignees
      Array(@raw.dig('assignees', 'nodes')).map { |a| a['login'] }
    end

    def labels
      Array(@raw.dig('labels', 'nodes')).map { |l| l['name'] }
    end

    def head_ref_name
      @raw['headRefName']
    end

    def base_ref_name
      @raw['baseRefName']
    end

    def additions
      @raw['additions'].to_i
    end

    def deletions
      @raw['deletions'].to_i
    end

    def changed_files
      @raw['changedFiles'].to_i
    end

    def commits_count
      @raw.dig('commits', 'totalCount').to_i
    end

    def reviews_count
      @raw.dig('reviews', 'totalCount').to_i
    end

    def review_requests_count
      @raw.dig('reviewRequests', 'totalCount').to_i
    end

    def merged_by
      @raw.dig('mergedBy', 'login')
    end

    def milestone
      @raw.dig('milestone', 'title')
    end

    def draft?
      @raw['isDraft']
    end

    def mergeable
      @raw['mergeable']
    end

    def merge_commit_oid
      @raw.dig('mergeCommit', 'oid')
    end
  end
end
