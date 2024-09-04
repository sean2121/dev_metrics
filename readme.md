# DevMetrics

DevMetrics is a RubyGem designed to collect repository metrics and generate reports in formats like Markdown and HTML. This README explains the basic usage of DevMetrics.

## Example Output Format

When using DevMetrics to generate reports, the output may look like the following example.
This example displays metrics for pull requests during a specific period.

```markdown
| Period  | Total PRs of the period | Corrections | Correction Rate | Lead Time of the PR   | PR Link |
|---------|-------------------------|-------------|-----------------|-----------------------|---------|
| 202401  | 12                      | 0           | 0.0%            | 0d 00:04:24           | [PRs for 202401](https://github.com/user/repo/pulls?q=is%3Apr+merged%3A202401) |
```


## Installation

### RubyGem
A RubyGem is a package (or library) of Ruby code that can be distributed and shared. Gems are used to extend the functionality of Ruby applications.

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
# Generate a Markdown report
DevMetrics.run(period: "2024-01", format: DevMetrics::MarkdownFormat)

# For more details about period, please see the github page.
# https://docs.github.com/en/search-github/getting-started-with-searching-on-github/understanding-the-search-syntax#query-for-dates
```

## Understanding the Code
`require 'dev_metrics'`: This line loads the DevMetrics gem so that you can use its functionality in your script.
`DevMetrics.configure:` This block allows you to set up the necessary configurations like access_token and repo_name.
`DevMetrics.run:` This method generates the report. You specify the period you want to analyze and the format of the report (e.g., Markdown).


## Running Your Ruby Script
To run the script (e.g., client.rb), open your terminal and navigate to the directory containing the script. Then, execute the following command:

```bash
ruby client.rb
```
This will run the script, generate the report to your current directory.

## License
This project is licensed under the MIT License.
