# frozen_string_literal: true

require 'date'
require 'fileutils'
require_relative 'file/helpers'

module StandupMD

  ##
  # Class for handling reading and writing standup files.
  class File
    include StandupMD::File::Helpers

    ##
    # Access to the class's configuration.
    #
    # @return [StandupMD::Config::EntryList]
    def self.config
      @config ||= StandupMD.config.file
    end

    ##
    # Find standup file in directory by file name.
    #
    # @param [String] File_naem
    def self.find(file_name)
      file = Dir.entries(config.directory).bsearch { |f| f == file_name }
      if file.nil? && !config.create
        raise "File #{file_name} not found." unless config.create
      end
      new(file_name)
    end

    ##
    # Find standup file in directory by Date object.
    #
    # @param [Date] date
    def self.find_by_date(date)
      unless date.is_a?(Date)
        raise ArgumentError, "Argument must be a Date object"
      end
      find(date.strftime(config.name_format))
    end

    ##
    # The list of entries in the file.
    #
    # @return [StandupMP::EntryList]
    attr_reader :entries

    ##
    # The name of the file.
    #
    # @return [String]
    attr_reader :name

    ##
    # Constructs the instance.
    #
    # @param [String] file_name
    #
    # @return [StandupMP::File]
    def initialize(file_name)
      @config = self.class.config
      if file_name.include?(::File::SEPARATOR)
        raise ArgumentError,
          "#{file_name} contains directory. Please use `StandupMD.config.file.directory=`"
      end

      unless ::File.directory?(@config.directory)
        raise "Dir #{@config.directory} not found." unless @config.create
        FileUtils.mkdir_p(@config.directory)
      end

      @name = ::File.expand_path(::File.join(@config.directory, file_name))

      unless ::File.file?(@name)
        raise "File #{@name} not found." unless @config.create
        FileUtils.touch(@name)
      end

      @new = ::File.zero?(@name)
      @loaded = false
    end

    ##
    # Was the file just now created?
    #
    # @return [Boolean] true if new
    def new?
      @new
    end

    ##
    # Has the file been loaded?
    #
    # @return [Boolean] true if loaded
    def loaded?
      @loaded
    end

    ##
    # Does the file exist?
    #
    # @return [Boolean] true if exists
    def exist?
      ::File.exist?(name)
    end

    ##
    # Loads the file's contents.
    # TODO clean up this method.
    #
    # @return [StandupMD::FileList]
    def load
      raise "File #{name} does not exist." unless ::File.file?(name)
      entry_list = EntryList.new
      record = {}
      section_type = ''
      ::File.foreach(name) do |line|
        line.chomp!
        next if line.strip.empty?
        if is_header?(line)
          unless record.empty?
            entry_list << new_entry(record)
            record = {}
          end
          record['header'] = line.sub(%r{^\#{#{@config.header_depth}}\s*}, '')
            section_type = @config.notes_header
            record[section_type] = []
        elsif is_sub_header?(line)
          section_type = determine_section_type(line)
          record[section_type] = []
        else
          record[section_type] << line.sub(bullet_character_regex, '')
        end
      end
      entry_list << new_entry(record) unless record.empty?
      @loaded = true
      @entries = entry_list.sort
      self
    rescue => e
      raise "File malformation: #{e}"
    end

    ##
    # Writes a new entry to the file if the first entry in the file isn't today.
    # This method is destructive; if a file for entries in the date range
    # already exists, it will be clobbered with the entries in the range.
    #
    # @param [Hash] start_and_end_date
    #
    # @return [Boolean] true if successful
    def write(dates = {})
      sorted_entries = entries.sort
      start_date = dates.fetch(:start_date, sorted_entries.first.date)
      end_date = dates.fetch(:end_date, sorted_entries.last.date)
      ::File.open(name, 'w') do |f|
        sorted_entries.filter(start_date, end_date).sort_reverse.each do |entry|
          f.puts header(entry.date)
          @config.sub_header_order.each do |attr|
            tasks = entry.send(attr)
            next if !tasks || tasks.empty?
            f.puts sub_header(@config.send("#{attr}_header").capitalize)
            tasks.each { |task| f.puts @config.bullet_character + ' ' + task }
          end
          f.puts
        end
      end
      true
    end
  end
end
