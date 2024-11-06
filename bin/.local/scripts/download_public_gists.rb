require 'net/http'
require 'json'
require 'fileutils'
require 'optparse'

# Parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: download_gists.rb [options]"

  opts.on("-u", "--username USERNAME", "GitHub username") do |u|
    options[:username] = u
  end

  opts.on("-d", "--directory DIRECTORY", "Directory to save gists") do |d|
    options[:directory] = d
  end
end.parse!

# Ensure required options are provided
if options[:username].nil? || options[:directory].nil?
  puts "Both --username and --directory options are required"
  exit
end

GITHUB_USERNAME = options[:username]
SAVE_DIR = options[:directory]

# Define base GitHub API URL for user gists
API_URL = "https://api.github.com/users/#{GITHUB_USERNAME}/gists"

# Ensure save directory exists
FileUtils.mkdir_p(SAVE_DIR)

# Function to download and save each public gist, handling pagination
def download_public_gists
  page = 1
  gists_fetched = 0

  loop do
    uri = URI("#{API_URL}?page=#{page}&per_page=100") # Adjust `per_page` to max of 100 for fewer requests
    response = Net::HTTP.get(uri)

    if response
      gists = JSON.parse(response)
      break if gists.empty?  # Exit loop when no more gists are available

      gists.each do |gist|
        gist_id = gist["id"]
        gist_description = gist["description"] || "No description"
        puts "Downloading gist #{gist_id}: #{gist_description}"

        # Loop through files in each gist
        gist["files"].each do |filename, file_info|
          file_url = file_info["raw_url"]

          # Download the file content
          file_content = Net::HTTP.get(URI(file_url))

          # Save the file locally
          save_path = File.join(SAVE_DIR, "#{gist_id}_#{filename}")
          File.write(save_path, file_content)
          puts "Saved #{filename} to #{save_path}"
        end
        gists_fetched += 1
      end

      page += 1  # Move to the next page of results
    else
      puts "Failed to retrieve gists for user #{GITHUB_USERNAME}"
      break
    end
  end

  puts "Downloaded #{gists_fetched} gists successfully!"
end

# Run the script
download_public_gists
