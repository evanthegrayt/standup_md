# frozen_string_literal: true

require "date"
require "fileutils"
require "standup_md/parsers/markdown"

module StandupMD
  ##
  # Class for handling reading and writing standup files.
  class File
    ##
    # Raised when a standup file or directory is missing and creation is off.
    class NotFoundError < StandardError; end

    class << self
      ##
      # Access to the class's configuration.
      #
      # @return [StandupMD::Config::File]
      def config
        StandupMD.config.file
      end

      ##
      # Convenience method for calling File.find(file_name).load.
      #
      # @param [String] file_name
      # @param [StandupMD::Config::File] config
      #
      # @return [StandupMD::File]
      def load(file_name, config: StandupMD.config.file)
        new(file_name, config: config).load
      end

      ##
      # Find standup file in directory by file name.
      #
      # @param [String] file_name
      # @param [StandupMD::Config::File] config
      #
      # @return [StandupMD::File]
      def find(file_name, config: StandupMD.config.file)
        new(file_name, config: config)
      end

      ##
      # Find standup file in directory by Date object.
      #
      # @param [Date] date
      # @param [StandupMD::Config::File] config
      #
      # @return [StandupMD::File]
      def find_by_date(date, config: StandupMD.config.file)
        raise ArgumentError, "Must be a Date object" unless date.is_a?(Date)

        find(date.strftime(config.name_format), config: config)
      end
    end

    ##
    # The list of entries in the file.
    #
    # @return [StandupMD::EntryList]
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
    # @param [StandupMD::Config::File] config
    #
    # @return [StandupMD::File]
    def initialize(file_name, config: StandupMD.config.file)
      @config = config
      @parser = StandupMD::Parsers::Markdown.new(@config)
      if file_name.include?(::File::SEPARATOR)
        raise ArgumentError,
          "#{file_name} contains directory. Configure the file directory separately."
      end

      ensure_directory
      @name = ::File.expand_path(::File.join(@config.directory, file_name))
      ensure_file

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
    #
    # @return [StandupMD::File]
    def load
      raise NotFoundError, "File #{name} does not exist." unless ::File.file?(name)

      @loaded = true
      @entries = @parser.parse(::File.read(name))
      self
    end

    ##
    # Writes entries to disk. This method is destructive; existing file contents
    # are replaced by the rendered entries in the requested date range.
    #
    # @param [Hash] {start_date: Date, end_date: Date}
    #
    # @return [Boolean] true if successful
    def write(**dates)
      raise ArgumentError, "No entries loaded for #{name}" if entries.nil? || entries.empty?

      sorted_entries = entries.sort
      start_date = dates.fetch(:start_date, sorted_entries.first.date)
      end_date = dates.fetch(:end_date, sorted_entries.last.date)
      ::File.write(
        name,
        @parser.render(sorted_entries, start_date: start_date, end_date: end_date)
      )
      true
    end

    private

    def ensure_directory
      return if ::File.directory?(@config.directory)
      raise NotFoundError, "Dir #{@config.directory} not found." unless @config.create

      FileUtils.mkdir_p(@config.directory)
    end

    def ensure_file
      return if ::File.file?(@name)
      raise NotFoundError, "File #{@name} not found." unless @config.create

      FileUtils.touch(@name)
    end
  end
end
