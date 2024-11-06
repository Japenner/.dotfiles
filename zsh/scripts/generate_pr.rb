require 'json'
require 'open3'
require 'logger'
require 'tempfile'
require 'optparse'
require_relative 'open_ai_client'

class GeneratePR
  PROMPT_TEMPLATE_PATH = File.expand_path("~/.dotfiles/zsh/templates/va-gov-pr-template.md")
  TEAM_REPOSITORY='department-of-veterans-affairs/VA.gov-team-forms'

  def initialize(api_key = nil, logger = Logger.new(STDOUT))
    @api_key = api_key
    @openai_client = OpenAIClient.new(api_key: @api_key)
    @logger = logger
  end

  def run
    # Step 1: Read PR template from an external file
    pr_template = File.read(PROMPT_TEMPLATE_PATH)

    # Step 2: Fetch ticket title and description
    ticket_details = get_ticket_details

    # Step 3: Fetch commit messages
    commit_messages = get_commit_messages

    # Step 4: Generate PR description
    pr_description = generate_pr_description(pr_template, ticket_details, commit_messages)

    # Step 5: Open the PR description in an editor for final review/editing
    final_description = edit_pr_description(pr_description)

    # Step 6: Output the final PR description and confirm
    @logger.info("Final PR Description:")
    @logger.info(final_description)

    # Confirm if user wants to proceed with creating the PR
    print "Do you want to create the PR with this description? (y/n): "
    input = gets.strip.downcase

    if input == 'y'
      # Use the GitHub CLI to create the PR with the final description
      system("gh pr create --body '#{final_description}'")
    else
      @logger.info("PR creation canceled.")
    end

  rescue => e
    @logger.info("Error: #{e.message}")
  end

  private

  # Read the PR template from an external file
  def read_template(file_path)
    File.read(file_path)
  end

  def get_ticket_details
    # Assuming branch name includes the ticket ID (e.g., `feature/1234-add-feature`)
    branch_name = `git branch --show-current`.strip
    branch = branch_name.split('/').last
    ticket_id = branch.split('-').first

    # Use `gh` to fetch the issue details (title and body)
    stdout, stderr, status = Open3.capture3("gh issue view #{ticket_id} --repo #{TEAM_REPOSITORY} --json title,body")
    raise "Failed to fetch ticket details: #{stderr}" unless status.success?

    issue = JSON.parse(stdout)
    { title: issue['title'], description: issue['body'] }
  end

  def get_commit_messages
    # Fetch commit messages not yet pushed to the main branch
    stdout, stderr, status = Open3.capture3("git log --oneline origin/main..HEAD")
    raise "Failed to fetch commit messages: #{stderr}" unless status.success?

    stdout.strip
  end

  def generate_pr_description(pr_template, ticket_details, commit_messages)
    client = OpenAIClient.new
    prompt = <<~PROMPT
      Generate a GitHub PR description using the following template. Incorporate relevant details from the ticket title, description, and commit messages:

      #{pr_template}

      Ticket Title:
      #{ticket_details[:title]}

      Ticket Description:
      #{ticket_details[:description]}

      Commit Messages:
      #{commit_messages}
    PROMPT

    fetch_feedback(prompt)
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

  def edit_pr_description(pr_description)
    # Create a temporary file with the PR description
    Tempfile.create('pr_description') do |file|
      file.write(pr_description)
      file.flush

      # Open the file in the default editor (or specify one)
      editor = ENV['EDITOR'] || 'nvim'
      system("#{editor} #{file.path}")

      # Read the potentially edited content back from the file
      file.rewind
      file.read.strip
    end
  end
end


# if ARGV.length < 1
#   puts "Usage: ruby generate_pr.rb <PULL_REQUEST_ID>"
#   exit 1
# end

api_key = ARGV[0]
logger = Logger.new(STDOUT).tap do |log|
  log.level = Logger::INFO
  log.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}] #{severity}: #{msg}\n"
  end
end

generate_pr = GeneratePR.new(api_key, logger)
generate_pr.run
