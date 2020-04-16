require 'date'
require 'fileutils'

class StandupMD
  VERSION = '0.1.0'

  ##
  # Instance variables that aren't settable by user, but are gettable.
  attr_reader :all_previous_entries, :current_entry, :previous_entry

  ##
  # Instance variables that are settable by the user, but have custom setters.
  attr_reader :directory, :bullet_character, :impediments, :current_entry_tasks

  ##
  # Instance variables with default getters and setters.
  attr_accessor :file_name_format, :entry_header_format, :current_header,
    :previous_header, :impediment_header

  ##
  # Constructor. Yields the instance so you can pass a block to access setters.
  def initialize
    set_default_instance_variables

    yield self if block_given?

    FileUtils.mkdir_p(directory) unless File.directory?(directory)

    set_internal_instance_variables
  end

  ##
  # The name of the current standup file.
  #
  # @return [String]
  def file
    @file ||= File.expand_path(File.join(
      directory, today.strftime(file_name_format)
    ))
  end

  ##
  # The tasks done on the previous day as an array.
  #
  # @return [Array]
  def previous_entry_tasks
    return @previous_entry_tasks if @previous_entry_tasks
    prev_entry = []
    yesterday = false
    previous_entry.each do |line|
      break if line.include?(impediment_header.strip)
      prev_entry << line.strip if yesterday
      yesterday = true if line.include?(current_header.strip)
    end
    @previous_entry_tasks = prev_entry
  end

  ##
  # The file that contains the previous entry. If previous entry was same month,
  # previous_file will be the same as file. If previous entry was last month,
  # and a file exists for last month, previous_file is last month's file.
  # If neither is true, returns an empty string.
  #
  # @return [String]
  def previous_file
    @previous_file ||=
      if File.file?(file)
        file
      else
        FileUtils.touch(file)
        prev_month_file = File.expand_path(File.join(
          directory,
          today.prev_month.strftime(file_name_format)
        ))
        File.file?(prev_month_file) ? prev_month_file : ''
      end
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
  # If the directory doesn't exist, it will be created. Setting the directory,
  # by default, will reload entries. This can be overwritten with the `reload`
  # paramter.
  #
  # @param [String] directory
  # @param [Boolean] reload
  # @return [String]
  def directory=(directory, reload: true)
    @directory = File.expand_path(directory)
    set_internal_instance_variables if reload
    @directory
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

  private

  ##
  # Scaffolding with which new entries will be created.
  def new_entry # :nodoc:
    [
      header,
      previous_header,
      previous_entry_tasks,
      current_header,
      current_entry_tasks.map { |e| "- #{e}" },
      impediment_header,
      impediments.map { |i| "- #{i}" },
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
    @header ||= today.strftime(entry_header_format)
  end

  ##
  # The first two entries in previous_file. An 'entry' is lines separated by a
  # double newline.
  def first_two_entries_of_file # :nodoc:
    return @first_two_entries_of_file if @first_two_entries_of_file
    entry_count = 0
    first  = []
    second = []
    all_previous_entries.each do |line|
      if line.strip.empty?
        break if entry_count == 1
        entry_count += 1
      end
      first << line if entry_count == 0
      second << line if entry_count == 1
    end
    @first_two_entries_of_file = [first, second]
  end

  ##
  # Convenience method for first entry of previous_file.
  def first_entry_of_file # :nodoc:
    @first_entry_of_file ||=
      first_two_entries_of_file.first.delete_if do |e|
        e.strip.chomp.empty?
      end
  end

  ##
  # Convenience method for second entry of previous_file.
  def second_entry_of_file # :nodoc:
    @second_entry_of_file ||=
      first_two_entries_of_file.last.delete_if do |e|
        e.strip.chomp.empty?
      end
  end

  ##
  # Sets default instance variables. Called when first instantiated.
  def set_default_instance_variables # :nodoc:
    @bullet_character = '-'
    @current_entry_tasks = ["<!-- ADD TODAY'S WORK HERE -->"]
    @impediments = ['None']
    @file_name_format = '%Y_%m.md'
    @directory = File.join(ENV['HOME'], '.cache', 'standup_md')
    @entry_header_format = '# %Y-%m-%d'
    @current_header = '## Today'
    @previous_header = '## Previous'
    @impediment_header = '## Impediments'
  end

  ##
  # Sets internal instance variables. Called when first instantiated, or after
  # directory is set.
  def set_internal_instance_variables # :nodoc:
    @file_written = false
    @all_previous_entries =
      File.file?(previous_file) ? File.readlines(previous_file) : ['']
    @entry_previously_added = all_previous_entries.first.strip == header
    @previous_entry =
      @entry_previously_added ? second_entry_of_file : first_entry_of_file
    @current_entry = entry_previously_added? ? first_entry_of_file : new_entry
  end
end
