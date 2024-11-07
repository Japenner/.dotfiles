require 'json'
require 'time'
require 'fileutils'
require 'logger'
require_relative 'slack_status'

# TODO: handle Slack statuses correctly; handle breaks properly
class TimeTracker
  LOG_FILE = '.dotfiles/time_log.json'
  LOGGER = Logger.new(STDOUT)

  def initialize
    @log_path = File.expand_path("~/#{LOG_FILE}")
    initialize_log_file
    load_log
    @slack_status = SlackStatus.new
  end

  def clock_in
    if clocked_in?
      LOGGER.info("Already clocked in at #{@log[:clock_in]}.")
    else
      log_clock_in_time
      LOGGER.info("Clocked in at #{@log[:clock_in]}.")
      @slack_status.set_status("Working", ":computer:")
    end
  rescue StandardError => e
    LOGGER.error("Failed to clock in: #{e.message}")
  end

  def clock_out
    if clocked_in?
      log_clock_out_time
      LOGGER.info("Clocked out at #{@log[:clock_out]}. Total hours worked: #{@log[:hours_worked]}.")
      @slack_status.clear_status
    else
      LOGGER.warn("Clock out attempt without clocking in.")
      puts "You need to clock in first!"
    end
  rescue StandardError => e
    LOGGER.error("Failed to clock out: #{e.message}")
  end

  def break
    update_slack_status_for_break
    if @log[today] && @log[today][:break] && @log[today][:break].last && @log[today][:break].last[:break_end].nil?
      log_break_end_time
      LOGGER.info("Break ended at #{Time.now.iso8601}. Slack status set to 'Working'.")
    else
      log_break_start_time
    end
    LOGGER.info("Break started at #{Time.now.iso8601}. Slack status set to 'On Break'.")
  rescue StandardError => e
    LOGGER.error("Failed to set break status: #{e.message}")
  end

  private

  def initialize_log_file
    # Create the directory if it doesn’t exist
    FileUtils.mkdir_p(File.dirname(@log_path))

    # Create and initialize the log file if it doesn’t exist
    unless File.exist?(@log_path)
      File.write(@log_path, JSON.pretty_generate({})) # Initializes with an empty JSON object
      LOGGER.info("Log file created at #{@log_path}")
    end
  end

  def clocked_in?
    !!@log[:clock_in]
  end

  def log_clock_in_time
    @log[today] = {}
    @log[today][:clock_in] = current_time
    save_log
  end

  def log_break_start_time
    @log[today] = {} unless @log[today]
    @log[today][:break] = [] unless @log[today][:break]
    @log[today][:break] << { break_start: current_time }
    save_log
  end

  def log_break_end_time
    @log[today] = {} unless @log[today]
    @log[today][:break] = [] unless @log[today][:break]
    @log[today][:break].last[:break_end] = current_time
    save_log
  end

  def log_clock_out_time
    @log[today] = {} unless @log[today]
    @log[today][:clock_out] = current_time
    calculate_hours_worked
    save_log
  end

  def update_slack_status_for_break
    @slack_status.status_text = "On Break"
    @slack_status.set_status
  end

  def today
    current_time.split('T').first
  end

  def current_time
    Time.now.iso8601
  end

  def load_log
    file_content = File.read(@log_path)
    @log = file_content.empty? ? {} : JSON.parse(file_content, symbolize_names: true)
  rescue JSON::ParserError => e
    LOGGER.error("Failed to load log: #{e.message}")
    @log = {}
  end

  def save_log
    File.write(@log_path, JSON.pretty_generate(@log))
  rescue StandardError => e
    LOGGER.error("Failed to save log: #{e.message}")
  end

  def parse_time(time_str)
    Time.parse(time_str)
  rescue ArgumentError => e
    LOGGER.error("Failed to parse time '#{time_str}': #{e.message}")
    Time.now
  end

  def hours_difference(start_time, end_time)
    ((end_time - start_time) / 3600).round(2)
  end

  def calculate_hours_worked
    start_time = parse_time(@log[:clock_in])
    end_time = parse_time(@log[:clock_out])
    @log[:hours_worked] = hours_difference(start_time, end_time)
  end

  def calculate_break_duration
    break_start = parse_time(@log[today][:break].last[:break_start])
    break_end = parse_time(@log[today][:break].last[:break_end])
    hours_difference(break_start, break_end)
  end

  def calculate_all_breaks_duration
    @log[today][:break].map do |break_log|
      break_start = parse_time(break_log[:break_start])
      break_end = parse_time(break_log[:break_end])
      hours_difference(break_start, break_end)
    end.sum
  end

  # Command-line interface method
  def self.run
    tracker = new
    case ARGV[0]
    when 'clock_in'
      tracker.clock_in
    when 'clock_out'
      tracker.clock_out
    when 'break'
      tracker.break
    else
      puts "Usage: ruby time_tracker.rb {clock_in|clock_out|break}"
    end
  end
end

# Run the CLI interface
TimeTracker.run if __FILE__ == $PROGRAM_NAME
