# frozen_string_literal: true

require_relative 'config/cli'
require_relative 'config/file'
require_relative 'config/entry'
require_relative 'config/entry_list'

module StandupMD

  ##
  # This class provides a connector from StandupMD to the configuration classes.
  class Config

    ##
    # Reader for Cli config.
    #
    # @return [StandupMD::Config::Cli]
    attr_reader :cli

    ##
    # Reader for File config.
    #
    # @return [StandupMD::Config::File]
    attr_reader :file

    ##
    # Reader for Entry config.
    #
    # @return [StandupMD::Config::Entry]
    attr_reader :entry

    ##
    # Reader for EntryList config.
    #
    # @return [StandupMD::Config::EntryList]
    attr_reader :entry_list

    ##
    # Builds the links to the configuration classes.
    def initialize
      @cli        = StandupMD::Config::Cli.new
      @file       = StandupMD::Config::File.new
      @entry      = StandupMD::Config::Entry.new
      @entry_list = StandupMD::Config::EntryList.new
    end
  end
end
