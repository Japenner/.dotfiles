# frozen_string_literal: true

require 'json'
require 'time'
require 'fileutils'
require 'logger'
require_relative 'slack_status'

# TODO: handle Slack statuses correctly; handle breaks properly
class TimeTracker
  LOG_FILE = '.dotfiles/time_log.json'
  LOGGER = Logger.new($stdout)

  def initialize
    @log_path = File.expand_path("~/#{LOG_FILE}")
    initialize_log_file
    @slack_status = SlackStatus.new
  rescue StandardError => e
    handle_error(e)
  end

  def clock_in
    if clocked_in?
      LOGGER.info("Already clocked in at #{todays_entry[:clock_in]}.")
    else
      update_todays_entry(:clock_in, current_time)
      LOGGER.info("Clocked in at #{todays_entry[:clock_in]}.")
      @slack_status.set_status('Working', ':computer:')
    end
  rescue StandardError => e
    handle_error
    LOGGER.error("Failed to clock in: #{e.message}")
  end

  def clock_out
    if clocked_in?
      log_clock_out_time
      LOGGER.info("Clocked out at #{todays_entry[:clock_out]}. Total hours worked: #{todays_entry[:hours_worked]}.")
      @slack_status.clear_status
    else
      LOGGER.warn('Clock out attempt without clocking in.')
      puts 'You need to clock in first!'
    end
  rescue StandardError => e
    handle_error
    LOGGER.error("Failed to clock out: #{e.message}")
  end

  def break
    # update_slack_status_for_break
    if on_break?
      log_break_end_time
      LOGGER.info("Break ended at #{Time.now.iso8601}. Slack status set to 'Working'.")
    else
      update_todays_entry(:break_start, current_time)
      LOGGER.info("Break started at #{Time.now.iso8601}. Slack status set to 'On Break'.")
      @slack_status.set_status('On Break', ':coffee:')
    end
  rescue StandardError => e
    handle_error
    LOGGER.error("Failed to set break status: #{e.message}")
  end

  private

  def initialize_log_file
    FileUtils.mkdir_p(File.dirname(@log_path))
    return if File.exist?(@log_path)

    File.write(@log_path, JSON.pretty_generate([new_entry(today)]))
    LOGGER.info("Log file created at #{@log_path}")
  rescue StandardError => e
    handle_error(e)
  end

  def clocked_in?
    puts "Today's Entry: #{todays_entry}"
    todays_entry[:clock_in] && todays_entry[:clock_out].nil?
  rescue StandardError => e
    handle_error(e)
  end

  def on_break?
    todays_entry[:breaks]&.last&.fetch(:break_start, nil) &&
      todays_entry[:breaks].last[:break_end]&.nil?
  rescue StandardError => e
    handle_error(e)
  end

  def log_break_end_time
    if on_break?
      update_todays_entry(:break_end, current_time)
    else
      LOGGER.warn('No active break to end.')
    end
  rescue StandardError => e
    handle_error(e)
  end

  def log_clock_out_time
    update_todays_entry(:clock_out, current_time)
    update_todays_entry(:hours_worked, calculate_hours_worked)
    print_end_of_day_summary
  rescue StandardError => e
    handle_error(e)
  end

  def today
    Time.now.strftime('%Y-%m-%d')
  rescue StandardError => e
    handle_error(e)
  end

  def current_time
    Time.now.iso8601
  rescue StandardError => e
    handle_error(e)
  end

  def log
    @log ||= JSON.parse(File.read(@log_path), symbolize_names: true).map(&:to_h)
  rescue StandardError => e
    handle_error(e)
  end

  def todays_entry
    log.find { |entry| entry['date'] == today }
  rescue StandardError => e
    handle_error(e)
  end

  def update_log_file(key, val, date)
    log.each do |entry|
      next unless entry['date'] == date

      # Update the specific key within the entry
      entry[key] = val
      puts "Updated entry: #{entry}"
      break
    end

    # Write the updated hash back to the JSON file
    File.write(@log_path, JSON.pretty_generate(log))
  rescue StandardError => e
    handle_error
    LOGGER.error("Failed to update log: #{e.message}")
  end

  def update_todays_entry(key, value)
    if %i[break_start break_end].include?(key)
      update_breaks(key, value, today)
    else
      update_log_file(key, value, today)
    end
  rescue StandardError => e
    handle_error(e)
  end

  def update_breaks(key, value, date)
    # Initialize the breaks array if it doesn't exist
    breaks = todays_entry[:breaks] || []

    # if breaks.empty?
    #   breaks << { break_start: nil, break_end: nil }
    #   breaks.last[:key] = value
    # end

    if key == :break_start
      breaks << { break_start: value, break_end: nil }
    elsif key == :break_end && on_break?
      breaks.last[:break_end] = value
    else
      LOGGER.warn('No active break to end.')
    end

    update_log_file(:breaks, breaks, date)
  rescue StandardError => e
    handle_error
    LOGGER.error("Failed while updating breaks: #{e.message}")
  end

  def calculate_hours_worked
    start_time = parse_time(todays_entry[:clock_in])
    end_time = parse_time(todays_entry[:clock_out])
    breaks_duration = calculate_breaks_duration
    hours_difference(start_time, end_time) - breaks_duration
  rescue StandardError => e
    handle_error(e)
  end

  def calculate_breaks_duration
    todays_entry[:breaks].map do |break_log|
      break_start = parse_time(break_log[:break_start])
      break_end = parse_time(break_log[:break_end])
      hours_difference(break_start, break_end)
    end.sum
  rescue StandardError => e
    handle_error(e)
  end

  def hours_difference(start_time, end_time)
    ((end_time - start_time) / 3600).round(2)
  rescue StandardError => e
    handle_error(e)
  end

  def parse_time(time_str)
    Time.parse(time_str)
  rescue ArgumentError => e
    LOGGER.error("Failed to parse time '#{time_str}': #{e.message}")
    Time.now
  rescue StandardError => e
    handle_error(e)
  end

  def new_entry(date)
    {
      date: date,
      clock_in: nil,
      clock_out: nil,
      breaks: [{ break_start: nil, break_end: nil }],
      hours_worked: 0
    }
  rescue StandardError => e
    handle_error(e)
  end

  def print_end_of_day_summary
    LOGGER.info('End of day summary:')
    LOGGER.info("Clocked in at: #{todays_entry[:clock_in]}")
    LOGGER.info("Clocked out at: #{todays_entry[:clock_out]}")
    LOGGER.info("Breaks taken: #{todays_entry[:breaks].size} (#{calculate_breaks_duration} hours)")
    LOGGER.info("Total hours worked: #{todays_entry[:hours_worked]}")
  rescue StandardError => e
    handle_error(e)
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
      puts 'Usage: ruby time_tracker.rb {clock_in|clock_out|break}'
    end
  rescue StandardError => e
    handle_error(e)
  end

  def handle_error(error)
    puts 'Error! - Message:'
    puts error.message
    puts "\n"
    puts 'Trace:'
    puts "#{error.backtrace.first(5).join("\n")}\n"
    exit 1
  end
end

# Run the CLI interface
TimeTracker.run if __FILE__ == $PROGRAM_NAME
