# frozen_string_literal: true

require 'date'
require 'fileutils'
require_relative 'standup_md/version'

##
# The class for handing reading/writing of entries.
#
# @example
#   su = StandupMD.new
class StandupMD

  ##
  # Convenience method for calling +new+ + +load+
  #
  # @param [Hash] attributes Attributes to set before loading.
  #
  # @example
  #   su = StandupMD.load(bullet_character: '*')
  def self.load(attributes = {})
    self.new do |s|
      attributes.each do |k, v|
        next unless s.respond_to?(k)
        s.send("#{k}=", v)
      end
    end.load
  end

  # :section: Attributes that aren't settable by user, but are gettable.

  ##
  # The string that will be used for the entry headers.
  #
  # @return [String]
  attr_reader :header

  ##
  # The file name should equal file_name_format parsed by Date.strftime.
  # The default is +Date.today.strftime('%Y_%m.md')+
  #
  # @return [String]
  #
  # @example
  #   su = StandupMD.new { |s| s.file_name_format = '%y_%m.markdown' }
  #   su.file
  #   # => Users/johnsmith/.cache/standup_md/20_04.markdown
  attr_reader :file

  ##
  # The file that contains previous entries. When last month's file exists, but
  # this month's doesn't or is empty, previous_file should equal last month's
  # file.
  #
  # @return [String]
  #
  # @example
  #   # Assuming the current month is April, 2020
  #
  #   Dir.entries(su.directory)
  #   # => []
  #   su = StandupMD.new
  #   su.previous_file
  #   # => ''
  #
  #   Dir.entries(su.directory)
  #   # => ['2020_03.md']
  #   su = StandupMD.new
  #   su.previous_file
  #   # => '2020_03.md'
  #
  #   Dir.entries(su.directory)
  #   # => ['2020_03.md', '2020_04.md']
  #   su = StandupMD.new
  #   su.previous_file
  #   # => '2020_04.md'
  attr_reader :previous_file

  ##
  # The entry for today's date as a hash. If +file+ already has an entry for
  # today, it will be read and used as +current_entry+. If there is no entry
  # for today, one should be generated from scaffolding.
  #
  # @return [Hash]
  #
  # @example
  #   StandupMD.new.current_entry
  #   # => {
  #   #      '2020-04-02' => {
  #   #        'Previous' => ['Task from yesterday'],
  #   #        'Current' => ["<!-- ADD TODAY'S WORK HERE -->"],
  #   #        'Impediments' => ['None'],
  #   #        'Notes' => [],
  #   #      }
  #   #    }
  attr_reader :current_entry

  ##
  # All previous entry for the same month as today. If it's the first day of
  # the month, +all_previous_entries+ will be all of last month's entries. They
  # will be a hash in the same format as +current_entry+.
  #
  # @return [Hash]
  attr_reader :all_previous_entries

  ##
  # Current entry plus all previous entries. This will be a hash in the same
  # format at +current_entry+ and +all_previous_entries+.
  #
  # @return [Hash]
  attr_reader :all_entries

  # :section: Attributes that are settable by the user, but have custom setters.

  ##
  # The directory where the markdown files are kept.
  #
  # @return [String]
  #
  # @default
  #   File.join(ENV['HOME'], '.cache', 'standup_md')
  attr_reader :directory

  ##
  # Array of tasks for today. This is the work expected to be performed today.
  # Default is an empty array, but when writing to file, the default is
  #
  # @return [Array]
  #
  # @default
  #   ["<!-- ADD TODAY'S WORK HERE -->"]
  attr_reader :current_entry_tasks

  ##
  # Array of impediments for today's entry.
  #
  # @return [Array]
  attr_reader :impediments

  ##
  # Character used as bullets for list entries.
  #
  # @return [String] either - (dash) or * (asterisk)
  attr_reader :bullet_character

  ##
  # Number of octothorps that should preface entry headers.
  #
  # @return [Integer] between 1 and 5
  attr_reader :header_depth

  ##
  # Number of octothorps that should preface sub-headers.
  #
  # @return [Integer] between 2 and 6
  attr_reader :sub_header_depth

  ##
  # The tasks from the previous task's "Current" section.
  #
  # @return [Array]
  attr_reader :previous_entry_tasks

  ##
  # Array of notes to add to today's entry.
  #
  # @return [Array]
  attr_reader :notes

  # :section: Attributes with default getters and setters.

  ##
  # The format to use for file names. This should include a month (%m) and
  # year (%y) so the file can rotate every month. This will prevent files
  # from getting too large.
  #
  # @param [String] file_name_format Parsed by +strftime+
  #
  # @return [String]
  attr_accessor :file_name_format

  ##
  # The date format to use for entry headers.
  #
  # @param [String] header_date_format Parsed by +strftime+
  #
  # @return [String]
  attr_accessor :header_date_format

  ##
  # The header to use for the +Current+ section.
  #
  # @param [String] current_header
  #
  # @return [String]
  attr_accessor :current_header

  ##
  # The header to use for the +Previous+ section.
  #
  # @param [String] previous_header
  #
  # @return [String]
  attr_accessor :previous_header

  ##
  # The header to use for the +Impediments+ section.
  #
  # @param [String] impediments_header
  #
  # @return [String]
  attr_accessor :impediments_header

  ##
  # The header to use for the +Notes+ section.
  #
  # @param [String] notes_header
  #
  # @return [String]
  attr_accessor :notes_header

  ##
  # Constructor. Yields the instance so you can pass a block to access setters.
  #
  # @return [self]
  #
  # @example
  #   su = StandupMD.new do |s|
  #     s.directory = @workdir
  #     s.file_name_format = '%y_%m.markdown'
  #     s.bullet_character = '*'
  #   end
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
  end

  # :section: Booleans
  # Helper methods for booleans.

  ##
  # Has the file been written since instantiated?
  #
  # @return [boolean]
  #
  # @example
  #   su = StandupMD.new
  #   su.file_written?
  #   # => false
  #   su.write
  #   su.file_written?
  #   # => true
  def file_written?
    @file_written
  end

  ##
  # Was today's entry already in the file?
  #
  # @return [boolean] true if today's entry was already in the file
  def entry_previously_added?
    @entry_previously_added
  end

  # :section: Custom setters
  # Setters that required validations.

  ##
  # Setter for current entry tasks.
  #
  # @param [Array] tasks
  #
  # @return [Array]
  def previous_entry_tasks=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @previous_entry_tasks = tasks
  end

  ##
  # Setter for notes.
  #
  # @param [Array] notes
  #
  # @return [Array]
  def notes=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @notes = tasks
  end

  ##
  # Setter for current entry tasks.
  #
  # @param [Array] tasks
  #
  # @return [Array]
  def current_entry_tasks=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @current_entry_tasks = tasks
  end

  ##
  # Setter for impediments.
  #
  # @param [Array] tasks
  #
  # @return [Array]
  def impediments=(tasks)
    raise 'Must be an Array' unless tasks.is_a?(Array)
    @impediments = tasks
  end

  ##
  # Setter for bullet_character. Must be * (asterisk) or - (dash).
  #
  # @param [String] character
  #
  # @return [String]
  def bullet_character=(character)
    raise 'Must be "-" or "*"' unless %w[- *].include?(character)
    @bullet_character = character
  end

  ##
  # Setter for directory. Must be expanded in case the user uses `~` for home.
  # If the directory doesn't exist, it will be created. To reset instance
  # variables after changing the directory, you'll need to call load.
  #
  # @param [String] directory
  #
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
  #
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
  #
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
  #
  # @return [Array]
  def sub_header_order=(array)
    order = %w[previous current impediments notes]
    raise "Values must be #{order.join{', '}}" unless order.sort == array.sort
    @sub_header_order = array
  end

  # :section: Misc
  # Misc.

  ##
  # Return a copy of the sub-header order so the user can't modify the array.
  #
  # @return [Array]
  def sub_header_order
    @sub_header_order.dup
  end

  ##
  # Writes a new entry to the file if the first entry in the file isn't today.
  #
  # @return [Boolean]
  def write
    File.open(file, 'w') do |f|
      all_entries.each do |head, s_heads|
        f.puts '#' * header_depth + ' ' + head
        sub_header_order.map { |value| "#{value}_header" }.each do |sub_head|
          sh = send(sub_head).capitalize
          next if !s_heads[sh] || s_heads[sh].empty?
          f.puts '#' * sub_header_depth + ' ' + sh
          s_heads[sh].each { |task| f.puts bullet_character + ' ' + task }
        end
        f.puts
        break if new_month?
      end
    end
    @file_written = true
  end

  ##
  # Sets internal instance variables. Called when first instantiated, or after
  # directory is set.
  #
  # @return [self]
  def load
    FileUtils.mkdir_p(directory) unless File.directory?(directory)

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
    self
  end

  ##
  # Alias of +load+
  #
  # @return [self]
  alias_method :reload, :load

  ##
  # Is today a different month than the previous entry?
  def new_month?
    file != previous_file
  end

  private

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

  def get_all_previous_entries # :nodoc:
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
