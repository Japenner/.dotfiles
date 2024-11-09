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
    initialize_log
    @slack_status = SlackStatus.new
  end

  def clock_in
    if clocked_in?
      LOGGER.info("Already clocked in at #{log.dig(today, :clock_in)}.")
    else
      update_todays_entry(:clock_in, current_time)
      LOGGER.info("Clocked in at #{log.dig(today, :clock_in)}.")
      @slack_status.set_status('Working', ':computer:')
    end
  rescue StandardError => e
    LOGGER.error("Failed to clock in: #{e.message}")
  end

  def clock_out
    if clocked_in?
      log_clock_out_time
      LOGGER.info("Clocked out at #{log.dig(today, :clock_out)}. Total hours worked: #{log.dig(today, :hours_worked)}.")
      @slack_status.clear_status
    else
      LOGGER.warn('Clock out attempt without clocking in.')
      puts 'You need to clock in first!'
    end
  rescue StandardError => e
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
    LOGGER.error("Failed to set break status: #{e.message}")
  end

  private

  def initialize_log_file
    FileUtils.mkdir_p(File.dirname(@log_path))
    return if File.exist?(@log_path)

    File.write(@log_path, JSON.pretty_generate({}))
    LOGGER.info("Log file created at #{@log_path}")
  end

  def clocked_in?
    log.dig(today, :clock_in) && log.dig(today, :clock_out).nil?
  end

  def on_break?
    log.dig(today,
            :breaks)&.any? && log.dig(today,
                                      :breaks)&.last&.fetch(:break_start, nil) && log.dig(today,
                                                                                          :breaks).last[:break_end].nil?
  end

  def log_break_end_time
    if on_break?
      update_todays_entry(:break_end, current_time)
    else
      LOGGER.warn('No active break to end.')
    end
  end

  def log_clock_out_time
    update_todays_entry(:clock_out, current_time)
    update_todays_entry(:hours_worked, calculate_hours_worked)
    print_end_of_day_summary
  end

  def today
    Time.now.strftime('%Y-%m-%d')
  end

  def current_time
    Time.now.iso8601
  end

  def initialize_log
    @log = {} if File.read(@log_path).empty?
  rescue JSON::ParserError => e
    LOGGER.error("Failed to initialize log: #{e.message}")
    @log = {}
  end

  def log
    @log ||= JSON.parse(File.read(@log_path), symbolize_names: true).to_h
  end

  def update_log_file(key, value, date)
    todays_entry = log[date] ||= {
      clock_in: nil,
      clock_out: nil,
      breaks: [{ break_start: nil, break_end: nil }],
      hours_worked: 0
    }

    # Update the specific key within the entry
    todays_entry[key] = value

    # Write the updated hash back to the JSON file
    File.write(@log_path, JSON.pretty_generate(log))
  rescue StandardError => e
    LOGGER.error("Failed to update log: #{e.message}")
  end

  def update_todays_entry(key, value)
    update_breaks(key, value, today) if %i[break_start break_end].include?(key)

    update_log_file(key, value, today)
  end

  def update_breaks(key, value, date)
    return unless %i[break_start break_end].include?(key)

    breaks = log[today][:breaks]

    breaks.last.merge(key => value) if on_break?
    breaks << { break_start: value, break_end: nil } if key == :break_start

    update_log_file(:breaks, breaks, date)
  rescue StandardError => e
    LOGGER.error("Failed while updating breaks: #{e.message}")
  end

  def calculate_hours_worked
    start_time = parse_time(log.dig(today, :clock_in))
    end_time = parse_time(log.dig(today, :clock_out))
    breaks_duration = calculate_breaks_duration
    hours_difference(start_time, end_time)
    update_todays_entry(:hours_worked, day_length - breaks_duration)
  end

  def calculate_breaks_duration
    @log[today][:breaks].map do |break_log|
      break_start = parse_time(break_log[:break_start])
      break_end = parse_time(break_log[:break_end])
      hours_difference(break_start, break_end)
    end.sum
  end

  def hours_difference(start_time, end_time)
    ((end_time - start_time) / 3600).round(2)
  end

  def parse_time(time_str)
    Time.parse(time_str)
  rescue ArgumentError => e
    LOGGER.error("Failed to parse time '#{time_str}': #{e.message}")
    Time.now
  end

  def print_end_of_day_summary
    LOGGER.info('End of day summary:')
    LOGGER.info("Clocked in at: #{log.dig(today, :clock_in)}")
    LOGGER.info("Clocked out at: #{log.dig(today, :clock_out)}")
    LOGGER.info("Breaks taken: #{todays_breaks.size} (#{calculate_breaks_duration} hours)")
    LOGGER.info("Total hours worked: #{log.dig(today, :hours_worked)}")
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
  end
end

# Run the CLI interface
TimeTracker.run if __FILE__ == $PROGRAM_NAME
