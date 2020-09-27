# frozen_string_literal: true

require 'optparse'
require_relative 'cli/helpers'

module StandupMD
  ##
  # Class for handing the command-line interface.
  class Cli
    include Helpers

    ##
    # Access to the class's configuration.
    #
    # @return [StandupMD::Config::Cli]
    def self.config
      @config ||= StandupMD.config.cli
    end

    ##
    # Prints output if +verbose+ is true.
    #
    # @return [nil]
    def self.echo(msg)
      puts msg if config.verbose
    end

    ##
    # Creates an instance of +StandupMD+ and runs what the user requested.
    def self.execute(options = [])
      exe = new(options)

      exe.write_file if config.write
      if config.print
        exe.print(exe.entry)
      elsif config.edit
        exe.edit
      end
    end

    ##
    # The entry searched for, usually today.
    #
    # @return [StandupMD::Entry]
    attr_reader :entry

    ##
    # Arguments passed at runtime.
    #
    # @return [Array] ARGV
    attr_reader :options

    ##
    # The file loaded.
    #
    # @return [StandupMD::File]
    attr_reader :file

    ##
    # Constructor. Sets defaults.
    #
    # @param [Array] options
    def initialize(options = [], load_config = true)
      @config = self.class.config
      @preference_file_loaded = false
      @options = options
      load_preferences if load_config
      load_runtime_preferences(options)
      @file = StandupMD::File.find_by_date(@config.date)
      @file.load
      @entry = new_entry(@file)
    end

    ##
    # Load the preference file.
    #
    # @return [nil]
    def load_preferences
      if ::File.exist?(@config.preference_file)
        ::StandupMD.load_config_file(@config.preference_file)
        @preference_file_loaded = true
      else
        echo "Preference file #{@config.preference_file} does not exist."
      end
    end

    ##
    # Has the preference file been loaded?
    #
    # @return boolean
    def preference_file_loaded?
      @preference_file_loaded
    end

    ##
    # Opens the file in an editor. Abandons the script.
    #
    # @return [nil]
    def edit
      echo "Opening file in #{@config.editor}"
      exec("#{@config.editor} #{file.name}")
    end

    ##
    # Writes entries to the file.
    #
    # @return [Boolean] true if file was written
    def write_file
      echo "Writing file #{file.name}"
      file.write
    end

    ##
    # Quick access to Cli.echo.
    #
    # @return [nil]
    def echo(msg)
      self.class.echo(msg)
    end
  end
end
