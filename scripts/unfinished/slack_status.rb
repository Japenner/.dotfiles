# frozen_string_literal: true

require 'net/http'
require 'json'
require 'time'
require 'logger'

# Logger setup
LOGGER = Logger.new($stdout)
LOGGER.level = Logger::INFO

# Slack status update class
class SlackStatus
  SLACK_WORKSPACES = {
    ad_hoc: ENV['AD_HOC_WORKSPACE_TOKEN']
  }.freeze

  STATUS_API_URL = 'https://slack.com/api/users.profile.set'

  attr_accessor :status_text, :status_emoji, :status_duration

  def initialize(status_text = 'Out of Office', status_emoji = ':palm_tree:', status_duration_hours = 8)
    @status_text = status_text
    @status_emoji = status_emoji
    @status_duration = status_duration_hours * 3600 # Convert hours to seconds
  end

  def set_status(text = @status_text, emoji = @status_emoji)
    execute_status_update(text, emoji, expiration_timestamp)
  end

  def clear_status
    execute_status_update('', '', 0)
  end

  private

  # Calculate expiration timestamp based on current time and duration
  def expiration_timestamp
    (Time.now + @status_duration).to_i
  end

  # Execute status update request to all workspaces
  def execute_status_update(text, emoji, expiration)
    SLACK_WORKSPACES.each do |workspace, token|
      response = post_status_update(token, text, emoji, expiration)
      log_response(response, workspace)
    rescue StandardError => e
      LOGGER.error("Failed to update status for workspace #{workspace}: #{e.message}")
    end
  end

  # Make a POST request to Slack API to set or clear status
  def post_status_update(token, text, emoji, expiration)
    uri = URI(STATUS_API_URL)
    request = build_request(uri, token, text, emoji, expiration)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

  # Build HTTP request for Slack status update
  def build_request(uri, token, text, emoji, expiration)
    Net::HTTP::Post.new(uri).tap do |request|
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type'] = 'application/json'
      request.body = {
        profile: {
          status_text: text,
          status_emoji: emoji,
          status_expiration: expiration
        }
      }.to_json
    end
  end

  # Log response for each workspace
  def log_response(response, workspace)
    response_body = JSON.parse(response.body)
    if response.is_a?(Net::HTTPSuccess) && response_body['ok']
      LOGGER.info("Status updated successfully for workspace #{workspace}")
    else
      LOGGER.error("Failed to update status for workspace #{workspace}: #{response_body['error']}")
    end
  end
end
