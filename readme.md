# DevMetrics
![dev_metrics_small (1)](https://github.com/user-attachments/assets/75c73232-6bff-479c-bca0-e0bf9a03b3ae)

DevMetrics is a powerful RubyGem designed to elevate your development workflow by automatically collecting and analyzing repository metrics. With DevMetrics, you can easily generate detailed reports in Markdown or HTML, helping you stay on top of your project's health and progress.

## Why Choose DevMetrics?
- Insightful Analytics: Get clear metrics on pull requests, correction rates, lead times, and more.
- Customizable Reports: Tailor the data to your needs with flexible configuration options
- Easy Integration: Seamlessly integrates with your GitHub repositories, providing actionable insights with minimal setup.

Built on DORA’s Four Key Metrics: DevMetrics aligns with industry-standard DevOps Research and Assessment (DORA) metrics—deployment frequency, lead time for changes, change failure rate, and time to restore service—to help you measure and improve engineering performance.

## Example Output Format

When using DevMetrics to generate reports, the output may look like the following example.
This example displays metrics for pull requests during a specific period.

```markdown
| Period  | Total PRs of the period | Corrections | Correction Rate | Lead Time of the PR   | PR Link |
|---------|-------------------------|-------------|-----------------|-----------------------|---------|
| 202401  | 12                      | 0           | 0.0%            | 0d 00:04:24           | [PRs for 202401](https://github.com/user/repo/pulls?q=is%3Apr+merged%3A202401) |
```


## Installation
### Ruby
Make sure Ruby is installed on your system by running the following command to check the version
```bash
ruby -v
```
### RubyGems
A RubyGems is a package (or library) of Ruby code that can be distributed and shared. Gems are used to extend the functionality of Ruby applications.

### Install via gem
```bash
gem install dev_metrics
```

### Bundler
add `dev_metrics` to your Gemfile:
```bash
gem 'dev_metrics'
```
Then, install it using Bundler:
```bash
bundle install
```

## Usage
1. Configuration
   Before using DevMetrics, you need to configure it using the configure method.

```ruby
# client.rb
require 'dev_metrics'

DevMetrics.configure do |c|
  c.access_token = "your_github_access_token" # required
  c.repo_name = "your_github_username/your_repository" # required
  c.bot_accounts = %w(bot) # optional. Account names that you don't want to include in the report.
  c.fix_branch_names = %w(fix hotfix rollback) # optional. Used to calculate the Correction Rate.
end
```

2. Running the Report
   You can generate a report by specifying the period and the format class.
```ruby
# client.rb
# Generate a Markdown report
DevMetrics.run(period: "2024-01", format: DevMetrics::MarkdownFormat)

# For more details about period, please see the github page.
# https://docs.github.com/en/search-github/getting-started-with-searching-on-github/understanding-the-search-syntax#query-for-dates
```

### 3. Define Your Own Output Format

You can define your own output class by inheriting from `DevMetrics::FormatBase`.  
Below is a more practical example that outputs a simple CSV report.

```ruby
# csv_report.rb
module DevMetrics
  class CsvReport < FormatBase
    private

    def data_format
      # CSV header and one line of metrics as an example
      [
        "period,total_prs,rollback_prs,correction_rate,lead_time",
        [
          metrics_calc.period,
          metrics_calc.prs_length,
          metrics_calc.rollback_prs_length,
          metrics_calc.failure_rate,
          metrics_calc.lead_time
        ].join(",")
      ].join("\n")
    end

    def write
      formatted_data = data_format
      File.open(output_filename, 'w') do |file|
        file.write(formatted_data)
      end
    end

    def output_filename
      "metrics_report.csv"
    end
  end
end
```

**How to use your custom format:**

```ruby
require 'dev_metrics'
require_relative './csv_report'

DevMetrics.configure do |c|
  c.access_token = "your_github_access_token"
  c.repo_name = "your_github_username/your_repository"
end

DevMetrics.run(period: "2024-01", format: DevMetrics::CsvReport)
```

This will generate a `metrics_report.csv` file with your metrics.

## Understanding the Code
- `require 'dev_metrics'`: This line loads the DevMetrics gem so that you can use its functionality in your script.
- `DevMetrics.configure:` This block allows you to set up the necessary configurations like access_token and repo_name.
- `DevMetrics.run:` This method generates the report. You specify the period you want to analyze and the format of the report (e.g., Markdown).


## Running Your Ruby Script
To run the script (e.g., client.rb), open your terminal and navigate to the directory containing the script. Then, execute the following command:

```bash
ruby client.rb
```
This will run the script, generate the report to your current directory.

## License
This project is licensed under the MIT License.

## MetricsCalc Methods Overview

Below is a list of main methods provided by `DevMetrics::MetricsCalc` and what each one does:

- **prs_length**  
  Returns the number of pull requests, excluding those created by bot accounts.

- **rollback_prs_length**  
  Returns the number of rollback PRs (PRs whose branch name matches fix patterns).

- **lead_time**  
  Returns the average lead time for PRs (from creation to merge) as a formatted string.

- **failure_rate**  
  Returns the failure rate (percentage of rollback PRs).

- **average_changed_line_size**  
  Returns the average PR size (additions + deletions).

- **average_changed_file**  
  Returns the average number of changed files per PR.

- **max_pr_size**  
  Returns the maximum PR size (additions + deletions).

- **min_pr_size**  
  Returns the minimum PR size (additions + deletions).

- **average_commits_count**  
  Returns the average number of commits per PR.

- **average_reviews_count**  
  Returns the average number of reviews per PR.

- **average_review_requests_count**  
  Returns the average number of review requests per PR.

- **draft_pr_rate**  
  Returns the percentage of PRs that are drafts.

- **label_counts**  
  Returns a hash with label names as keys and their counts as values.

- **assignee_counts**  
  Returns a hash with assignee names as keys and their counts as values.

- **milestone_counts**  
  Returns a hash with milestone titles as keys and their counts as values.

- **average_pr_age**  
  Returns the average PR age in days (from creation to close, or now if open).

- **max_pr_age**  
  Returns the maximum PR age in days.

- **min_pr_age**  
  Returns the minimum PR age in days.

- **draft_pr_count**  
  Returns the number of draft PRs.

- **merged_pr_count**  
  Returns the number of merged PRs.

- **closed_unmerged_pr_count**  
  Returns the number of closed but unmerged PRs.

---

You can use these methods in your custom format class to access and output any metrics you need.

## GitHub Actions Example: Automatically Create a Pull Request with Updated Metrics

Below is a sample GitHub Actions workflow that runs on a schedule, updates your development metrics (using your own script), and creates a pull request with the changes.

Save this as `.github/workflows/update_metrics.yml` in your repository.

```yaml
name: Update Development Metrics

on:
  schedule:
    - cron: '0 9 1 * *'  # Runs at 09:00 (UTC) on the 1st of every month
  workflow_dispatch:

jobs:
  update-metrics:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2  # or your preferred Ruby version

      - name: Install dependencies
        run: bundle install

      - name: Run metrics update script
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          ruby client.rb

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commit-message: "Update development metrics"
          title: "Update development metrics"
          body: "Automated update of development metrics."
          branch: update-metrics-${{ github.run_id }}
```

**How it works:**
- Runs monthly (or manually via workflow_dispatch).
- Checks out your code, sets up Ruby, and installs dependencies.
- Runs your custom script (e.g., `tools/update_development_metrics.rb`) to update metrics files.
- Commits any changes and creates a pull request automatically.

**Tips:**
- Replace `tools/update_development_metrics.rb` with your actual script path.
- Make sure your script generates or updates the metrics report file(s).
- You may need to set up repository secrets (like `GITHUB_TOKEN` or a personal access token) for authentication.

---
