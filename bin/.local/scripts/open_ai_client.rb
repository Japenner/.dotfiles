require 'net/http'
require 'json'
require 'logger'

class OpenAIClient
  attr_accessor :model, :api_key, :temperature, :max_tokens, :logger

  # Initialize with essential parameters
  def initialize(api_key: nil, model: 'gpt-4o-mini', temperature: 0.2, max_tokens: 1600, logger: Logger.new(STDOUT))
    @api_key = api_key || ENV['OPENAI_API_KEY']
    @model = model
    @temperature = temperature
    @max_tokens = max_tokens
    @logger = logger
  end

  # Send a prepared prompt to OpenAI and return the response
  def send_prompt(prompt)
    log_info("Sending prompt to OpenAI")
    response = send_to_openai(prompt)
    parse_response(response)
  rescue StandardError => e
    log_error("Error while sending prompt to OpenAI", error: e)
    nil
  end

  private

  # Perform the HTTP POST request to OpenAI
  def send_to_openai(prompt)
    uri = URI('https://api.openai.com/v1/chat/completions')
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}"
    request.body = construct_payload(prompt)

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
      response.body
    end
  end

  # Construct the request payload
  def construct_payload(prompt)
    {
      model: @model,
      messages: [{ role: 'user', content: prompt }],
      max_tokens: @max_tokens,
      temperature: @temperature
    }.to_json
  end

  # Parse the response JSON from OpenAI
  def parse_response(response)
    return unless response

    parsed = JSON.parse(response)
    message = parsed.dig('choices', 0, 'message', 'content')
    if message && !message.empty?
      log_info("Received response from OpenAI")
      message
    else
      log_error("Failed to parse response from OpenAI", response: response)
      nil
    end
  end

  # Logging utility methods
  def log_info(message, **context)
    logger.info({ message: message, context: context })
  end

  def log_error(message, **context)
    logger.error({ message: message, context: context })
  end
end
