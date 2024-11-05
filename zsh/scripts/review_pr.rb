# review_pr.rb

require 'open3'
require 'logger'
require_relative 'open_ai_client'

class ReviewPR
  PROMPT_TEMPLATE_PATH = File.expand_path('~/.dotfiles/zsh/prompts/review_pr.md')
  GITHUB_REPO = "department-of-veterans-affairs/vets-api"

  def initialize(pull_request_id, api_key = nil, logger = Logger.new(STDOUT))
    @pull_request_id = pull_request_id
    @api_key = api_key
    @openai_client = OpenAIClient.new(api_key: @api_key)
    @logger = logger
  end

  def run
    @logger.info("Starting review for PR ##{@pull_request_id}")
    diff = fetch_pr_diff
    return unless diff

    prompt = prepare_prompt(diff)
    response = fetch_feedback(prompt)
    display_feedback(response)
  end

  private

  def fetch_pr_diff
    @logger.info("Fetching PR diff for ##{@pull_request_id}...")
    diff, status = Open3.capture2("gh pr diff #{@pull_request_id}")

    if status.success?
      @logger.debug("Successfully fetched diff.")
      diff
    else
      @logger.error("Failed to retrieve PR diff. Please check the pull request ID.")
      nil
    end
  end

  def prepare_prompt(diff)
    @logger.info("Preparing prompt with the PR diff...")
    prompt_template = File.read(PROMPT_TEMPLATE_PATH)
    prompt_template.gsub('$DIFF', diff)
  end

  def fetch_feedback(prompt)
    @logger.info("Sending prompt to OpenAI for feedback...")
    feedback = @openai_client.send_prompt(prompt)

    if feedback && !feedback.empty?
      @logger.debug("Feedback successfully retrieved from OpenAI.")
      feedback
    else
      @logger.error("No feedback received from OpenAI.")
      nil
    end
  end

  def display_feedback(feedback)
    if feedback
      puts "Feedback received:\n\n#{feedback}"
    else
      @logger.warn("No feedback to display.")
      puts "No feedback to display."
    end
  end
end

if ARGV.length < 1
  puts "Usage: ruby review_pr.rb <PULL_REQUEST_ID>"
  exit 1
end

api_key = ARGV[0]
pull_request_id = ARGV[1]
logger = Logger.new(STDOUT).tap do |log|
  log.level = Logger::INFO
  log.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}] #{severity}: #{msg}\n"
  end
end

review_pr = ReviewPR.new(api_key, pull_request_id, logger)
review_pr.run
