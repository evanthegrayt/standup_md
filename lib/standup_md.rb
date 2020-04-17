require 'date'
require 'fileutils'

class StandupMD
  VERSION = '0.1.0'

  ##
  # Instance variables that aren't settable by user, but are gettable.
  attr_reader :file, :previous_file, :current_entry, :previous_entry,
    :all_previous_entries

  ##
  # Instance variables that are settable by the user, but have custom setters.
  attr_reader :directory, :current_entry_tasks, :impediments, :bullet_character

  ##
  # Instance variables with default getters and setters.
  attr_accessor :file_name_format, :entry_header_format, :current_header,
    :previous_header, :impediment_header

  ##
  # Constructor. Yields the instance so you can pass a block to access setters.
  def initialize
    @bullet_character = '-'
    @current_entry_tasks = ["<!-- ADD TODAY'S WORK HERE -->"]
    @impediments = ['None']
    @file_name_format = '%Y_%m.md'
    @directory = File.join(ENV['HOME'], '.cache', 'standup_md')
    @entry_header_format = '# %Y-%m-%d'
    @current_header = '## Today'
    @previous_header = '## Previous'
    @impediment_header = '## Impediments'

    yield self if block_given?
    FileUtils.mkdir_p(directory) unless File.directory?(directory)

    set_internal_instance_variables
  end

  ##
  # The tasks done on the previous day as an array.
  #
  # @return [Array]
  def previous_entry_tasks
    prev_entry = []
    yesterday = false
    previous_entry.each do |line|
      break if line.include?(impediment_header.strip)
      prev_entry << line.strip if yesterday
      yesterday = true if line.include?(current_header.strip)
    end
    prev_entry
  end

  ##
  # Has the file been written since instantiated?
  #
  # @return [boolean]
  def file_written?
    @file_written
  end

  ##
  # Was today's entry already in the file?
  #
  # @return [boolean]
  def entry_previously_added?
    @entry_previously_added
  end

  ##
  # Setter for current entry tasks.
  #
  # @param [Array] tasks
  # @return [Array]
  def current_entry_tasks=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @current_entry_tasks = tasks
  end

  ##
  # Setter for impediments.
  #
  # @param [Array] tasks
  def impediments=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @impediments = tasks
  end

  ##
  # Setter for bullet_character. Must be * (asterisk) or - (dash).
  #
  # @param [String] character
  def bullet_character=(character)
    raise 'Must be "-" or "*"' unless %w[- *].include?(character)
    @bullet_character = character
  end

  ##
  # Setter for directory. Must be expanded in case the user uses ~ for home.
  # If the directory doesn't exist, it will be created. To reset instance
  # variables after changing the directory, you'll need to call reload!
  #
  # @param [String] directory
  # @return [String]
  def directory=(directory)
    directory = File.expand_path(directory)
    FileUtils.mkdir_p(directory) unless File.directory?(directory)
    @directory = directory
  end

  ##
  # Writes a new entry to the file if the first entry in the file isn't today.
  #
  # @return [Boolean]
  def write
    return false if entry_previously_added? || file_written?
    File.open(file, 'w') do |f|
      f.puts new_entry
      f.puts all_previous_entries if file == previous_file
    end
    @file_written = true
  end

  def reload!
    set_internal_instance_variables
  end

  private

  ##
  # Scaffolding with which new entries will be created.
  def new_entry # :nodoc:
    [
      header,
      previous_header,
      previous_entry_tasks,
      current_header,
      current_entry_tasks.map { |e| "#{bullet_character} #{e}" },
      impediment_header,
      impediments.map { |i| "#{bullet_character} #{i}" },
      ''
    ].flatten
  end

  ##
  # Date object of today's date.
  def today # :nodoc:
    @today ||= Date.today
  end

  ##
  # The header for today's entry.
  def header # :nodoc:
    today.strftime(entry_header_format)
  end

  ##
  # The first two entries in previous_file. An 'entry' is lines separated by a
  # double newline.
  def get_first_two_entries_of_file # :nodoc:
    entry_count = 0
    first  = []
    second = []
    all_previous_entries.each do |line|
      if line.strip.empty?
        break if entry_count == 1
        entry_count += 1
        next
      end
      first << line if entry_count == 0
      second << line if entry_count == 1
    end
    [first, second]
  end

  ##
  # Convenience method for first entry of previous_file.
  def first_entry_of_file # :nodoc:
    @first_two_entries_of_file.first
  end

  ##
  # Convenience method for second entry of previous_file.
  def second_entry_of_file # :nodoc:
    @first_two_entries_of_file.last
  end

  ##
  # Sets internal instance variables. Called when first instantiated, or after
  # directory is set.
  def set_internal_instance_variables # :nodoc:
    @file_written = false
    @file = File.expand_path(File.join(directory, today.strftime(file_name_format)))
    @previous_file = set_previous_file
    @all_previous_entries =
      File.file?(previous_file) ? File.readlines(previous_file).map(&:chomp) : ['']
    @first_two_entries_of_file = get_first_two_entries_of_file
    @entry_previously_added = all_previous_entries.first&.strip == header
    @previous_entry =
      @entry_previously_added ? second_entry_of_file : first_entry_of_file
    @current_entry = entry_previously_added? ? first_entry_of_file : new_entry

    FileUtils.touch(file) unless File.file?(file)
  end

  ##
  # The file that contains the previous entry. If previous entry was same month,
  # previous_file will be the same as file. If previous entry was last month,
  # and a file exists for last month, previous_file is last month's file.
  # If neither is true, returns an empty string.
  def set_previous_file # :nodoc:
    return file if File.file?(file) && !File.zero?(file)
    prev_month_file = File.expand_path(File.join(
      directory,
      today.prev_month.strftime(file_name_format)
    ))
    File.file?(prev_month_file) ? prev_month_file : ''
  end
end
