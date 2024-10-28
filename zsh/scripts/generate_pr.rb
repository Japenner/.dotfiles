require 'json'
require 'openai'
require 'open3'
require 'tempfile'

# Set your OpenAI API key
OpenAI.api_key = ENV['OPENAI_API_KEY']

# Read the PR template from an external file
def read_pr_template(file_path)
  File.read(file_path)
end

def get_ticket_details
  # Assuming branch name includes the ticket ID (e.g., `feature/1234-add-feature`)
  branch_name = `git branch --show-current`.strip
  ticket_id = branch_name.split('-').first

  # Use `gh` to fetch the issue details (title and body)
  stdout, stderr, status = Open3.capture3("gh issue view #{ticket_id} --json title,body")
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
  client = OpenAI::Client.new
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

  response = client.chat(
    parameters: {
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
      max_tokens: 500
    }
  )

  response['choices'].first['message']['content'].strip
end

def edit_pr_description(pr_description)
  # Create a temporary file with the PR description
  Tempfile.create('pr_description') do |file|
    file.write(pr_description)
    file.flush

    # Open the file in the default editor (or specify one)
    editor = ENV['EDITOR'] || 'vim'
    system("#{editor} #{file.path}")

    # Read the potentially edited content back from the file
    file.rewind
    file.read.strip
  end
end

def main
  begin
    # Step 1: Read PR template from an external file
    pr_template = read_pr_template("pr_template.txt")

    # Step 2: Fetch ticket title and description
    ticket_details = get_ticket_details

    # Step 3: Fetch commit messages
    commit_messages = get_commit_messages

    # Step 4: Generate PR description
    pr_description = generate_pr_description(pr_template, ticket_details, commit_messages)

    # Step 5: Open the PR description in an editor for final review/editing
    final_description = edit_pr_description(pr_description)

    # Step 6: Output the final PR description and confirm
    puts "Final PR Description:\n\n"
    puts final_description

    # Confirm if user wants to proceed with creating the PR
    print "Do you want to create the PR with this description? (y/n): "
    input = gets.strip.downcase

    if input == 'y'
      # Use the GitHub CLI to create the PR with the final description
      system("gh pr create --body '#{final_description}'")
    else
      puts "PR creation canceled."
    end

  rescue => e
    puts "Error: #{e.message}"
  end
end

main if __FILE__ == $0
