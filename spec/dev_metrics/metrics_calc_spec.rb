require_relative '../spec_helper'
require 'dev_metrics/metrics_calc'
require 'time'

RSpec.describe DevMetrics::MetricsCalc do
  let(:period) { "2025-04" }
  let(:config) { { bot_accounts: [], fix_branch_names: %w(hotfix fix rollback) } }

  let(:pr1) do
    double(
      additions: 10,
      deletions: 2,
      changed_files: 1,
      commits_count: 3,
      reviews_count: 2,
      review_requests_count: 1,
      draft?: false,
      labels: ["bug"],
      assignees: ["alice"],
      milestone: "v1.0",
      created_at: Time.parse("2025-04-01T10:00:00Z"),
      closed_at: Time.parse("2025-04-02T10:00:00Z"),
      merged_at: Time.parse("2025-04-02T10:00:00Z"),
      head_ref_name: "feature/abc",
      author: "alice"
    )
  end

  let(:pr2) do
    double(
      additions: 5,
      deletions: 5,
      changed_files: 2,
      commits_count: 2,
      reviews_count: 1,
      review_requests_count: 0,
      draft?: true,
      labels: ["enhancement"],
      assignees: ["bob"],
      milestone: "v1.0",
      created_at: Time.parse("2025-04-03T10:00:00Z"),
      closed_at: Time.parse("2025-04-04T10:00:00Z"),
      merged_at: nil,
      head_ref_name: "fix/xyz",
      author: "bob"
    )
  end

  let(:prs) { [pr1, pr2] }

  subject do
    described_class.new(
      prs,
      period,
      bot_accounts: config[:bot_accounts],
      fix_branch_names: config[:fix_branch_names]
    )
  end

  it "calculates prs_length" do
    expect(subject.prs_length).to eq 2
  end

  it "calculates rollback_prs_length" do
    expect(subject.rollback_prs_length).to eq 1
  end

  it "calculates average_changed_line_size" do
    expect(subject.average_changed_line_size).to eq 11.0
  end

  it "calculates average_commits_count" do
    expect(subject.average_commits_count).to eq 2.5
  end

  it "calculates draft_pr_rate" do
    expect(subject.draft_pr_rate).to eq 50.0
  end

  it "calculates label_counts" do
    expect(subject.label_counts).to eq({ "bug" => 1, "enhancement" => 1 })
  end

  it "calculates assignee_counts" do
    expect(subject.assignee_counts).to eq({ "alice" => 1, "bob" => 1 })
  end

  it "calculates milestone_counts" do
    expect(subject.milestone_counts).to eq({ "v1.0" => 2 })
  end

  it "calculates average_pr_age" do
    expect(subject.average_pr_age).to be_a(Float)
  end

  it "calculates draft_pr_count" do
    expect(subject.draft_pr_count).to eq 1
  end

  it "calculates merged_pr_count" do
    expect(subject.merged_pr_count).to eq 1
  end

  it "calculates closed_unmerged_pr_count" do
    expect(subject.closed_unmerged_pr_count).to eq 1
  end
end
