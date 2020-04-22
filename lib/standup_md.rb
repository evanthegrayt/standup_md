require 'date'
require 'fileutils'

class StandupMD
  VERSION = '0.0.9'

  ##
  # Instance variables that aren't settable by user, but are gettable.
  attr_reader :file, :previous_file, :current_entry, :all_previous_entries,
    :all_entries

  ##
  # Instance variables that are settable by the user, but have custom setters.
  attr_reader :directory, :current_entry_tasks, :impediments, :bullet_character,
    :header_depth, :sub_header_depth, :previous_entry_tasks, :notes

  ##
  # Instance variables with default getters and setters.
  attr_accessor :file_name_format, :header_date_format, :current_header,
    :previous_header, :impediments_header, :notes_header

  ##
  # Constructor. Yields the instance so you can pass a block to access setters.
  def initialize
    @notes = []
    @header_depth = 1
    @sub_header_depth = 2
    @bullet_character = '-'
    @current_entry_tasks = ["<!-- ADD TODAY'S WORK HERE -->"]
    @impediments = ['None']
    @file_name_format = '%Y_%m.md'
    @directory = File.join(ENV['HOME'], '.cache', 'standup_md')
    @header_date_format = '%Y-%m-%d'
    @current_header = 'Current'
    @previous_header = 'Previous'
    @impediments_header = 'Impediments'
    @notes_header = 'Notes'
    @sub_header_order = %w[previous current impediments notes]

    yield self if block_given?
    FileUtils.mkdir_p(directory) unless File.directory?(directory)

    set_internal_instance_variables
  end

  # :section: Booleans
  # Helper methods for booleans.

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

  # :section: Custom setters
  # Setters that required validations.

  ##
  # Setter for current entry tasks.
  #
  # @param [Array] tasks
  # @return [Array]
  def previous_entry_tasks=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @previous_entry_tasks = tasks
  end

  ##
  # Setter for notes.
  #
  # @param [Array] notes
  # @return [Array]
  def notes=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @notes = tasks
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
  # @return [Array]
  def impediments=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @impediments = tasks
  end

  ##
  # Setter for bullet_character. Must be * (asterisk) or - (dash).
  #
  # @param [String] character
  # @return [String]
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
    # TODO test this
    directory = File.expand_path(directory)
    FileUtils.mkdir_p(directory) unless File.directory?(directory)
    @directory = directory
  end

  ##
  # Number of octothorps (#) to use before the main header.
  #
  # @param [Integer] depth
  # @return [Integer]
  def header_depth=(depth)
    if !depth.between?(1, 5)
      raise 'Header depth out of bounds (1..5)'
    elsif depth >= sub_header_depth
      raise 'header_depth must be larger than sub_header_depth'
    end
    @header_depth = depth
  end

  ##
  # Number of octothorps (#) to use before sub headers (Current, Previous, etc).
  #
  # @param [Integer] depth
  # @return [Integer]
  def sub_header_depth=(depth)
    if !depth.between?(2, 6)
      raise 'Sub-header depth out of bounds (2..6)'
    elsif depth <= header_depth
      raise 'sub_header_depth must be smaller than header_depth'
    end
    @sub_header_depth = depth
  end

  ##
  # Preferred order for sub-headers.
  #
  # @param [Array] Values must be %w[previous current impediment notes]
  # @return [Array]
  def sub_header_order=(array)
    order = %w[previous current impediments notes]
    raise "Values must be #{order.join{', '}}" unless order.sort == array.sort
    @sub_header_order = array
  end

  ##
  # Return a copy of the sub-header order so the user can't modify the array.
  #
  # @return [Array]
  def sub_header_order
    @sub_header_order.dup
  end

  # :section: Misc
  # Misc.

  ##
  # Writes a new entry to the file if the first entry in the file isn't today.
  #
  # @return [Boolean]
  def write
    File.open(file, 'w') do |f|
      all_entries.each do |head, s_heads|
        f.puts '#' * header_depth + ' ' + head
        sub_header_order.map { |value| "#{value}_header" }.each do |sh|
          tasks = s_heads[send(sh).capitalize]
          if tasks && !tasks.empty?
            f.puts '#' * sub_header_depth + ' ' + send(sh).capitalize
            s_heads[send(sh).capitalize].each do |task|
              f.puts bullet_character + ' ' + task
            end
          end
        end
        f.puts
      end
    end
    @file_written = true
  end

  def reload!
    set_internal_instance_variables
  end

  private

  # :section: Private
  # Private methods.

  ##
  # Scaffolding with which new entries will be created.
  def new_entry # :nodoc:
    {
      previous_header => previous_entry_tasks || [],
      current_header => current_entry_tasks,
      impediments_header => impediments,
      notes_header => notes,
    }
  end

  ##
  # Date object of today's date.
  def today # :nodoc:
    @today
  end

  ##
  # The header for today's entry.
  def header # :nodoc:
    @header
  end

  ##
  # Sets internal instance variables. Called when first instantiated, or after
  # directory is set.
  def set_internal_instance_variables # :nodoc:
    @today = Date.today
    @header = today.strftime(header_date_format)
    @file_written = false
    @file = File.expand_path(File.join(directory, today.strftime(file_name_format)))
    @previous_file = get_previous_file
    @all_previous_entries = get_all_previous_entries
    @entry_previously_added = all_previous_entries.key?(header)
    @previous_entry_tasks = previous_entry[current_header]
    @current_entry = @all_previous_entries.delete(header) || new_entry
    @all_entries = {header => current_entry}.merge(all_previous_entries)

    FileUtils.touch(file) unless File.file?(file)
  end

  ##
  # The file that contains the previous entry. If previous entry was same month,
  # previous_file will be the same as file. If previous entry was last month,
  # and a file exists for last month, previous_file is last month's file.
  # If neither is true, returns an empty string.
  def get_previous_file # :nodoc:
    return file if File.file?(file) && !File.zero?(file)
    prev_month_file = File.expand_path(File.join(
      directory,
      today.prev_month.strftime(file_name_format)
    ))
    File.file?(prev_month_file) ? prev_month_file : ''
  end

  def get_all_previous_entries
    return {} unless File.file?(previous_file)
    prev_entries = {}
    entry_header = ''
    section_type = ''
    File.foreach(previous_file) do |line|
      line.chomp!
      next if line.strip.empty?
      if line.match(%r{^#{'#' * header_depth}\s+})
        entry_header = line.sub(%r{^\#{#{header_depth}}\s*}, '')
        section_type = notes_header
        prev_entries[entry_header] ||= {}
      elsif line.match(%r{^#{'#' * sub_header_depth}\s+})
        section_type = determine_section_type(
          line.sub(%r{^\#{#{sub_header_depth}}\s*}, '')
        )
        prev_entries[entry_header][section_type] = []
      else
        prev_entries[entry_header][section_type] << line.sub(
          %r{\s*#{bullet_character}\s*}, ''
        )
      end
    end
    prev_entries
  rescue => e
    raise "File malformation: #{e}"
  end

  def determine_section_type(line) # :nodoc:
    [
      current_header,
      previous_header,
      impediments_header,
      notes_header
    ].each { |header| return header if line.include?(header) }
    raise "Unknown header type [#{line}]"
  end

  def previous_entry # :nodoc:
    all_previous_entries.each do |key, value|
      return value unless key == header
    end
  end
end
