# frozen_string_literal: true

require_relative 'standup_md/version'
require_relative 'standup_md/file'
require_relative 'standup_md/entry'
require_relative 'standup_md/entry_list'
require_relative 'standup_md/cli'
require_relative 'standup_md/config'

##
# The main module for the gem. Provides access to configuration classes.
module StandupMD
  @config_file_loaded = false

  ##
  # Method for accessing the configuration.
  #
  # @return [StanupMD::Cli]
  def self.config
    @config ||= StandupMD::Config.new
  end

  ##
  # Reset all configuration values to their defaults.
  #
  # @return [StandupMD::Config]
  def self.reset_config
    @config = StandupMD::Config.new
  end

  ##
  # Allows for configuration via a block. Useful when making config files.
  #
  # @example
  #   StandupMD.configure { |s| s.cli.editor = 'mate' }
  def self.configure
    yield self.config
  end

  ##
  # Has a config file been loaded?
  #
  # @return [Boolean]
  def self.config_file_loaded?
    @config_file_loaded
  end

  ##
  # Loads a config file.
  #
  # @param [String] file
  def self.load_config_file(file)
    file = ::File.expand_path(file)
    raise "File #{file} does not exist." unless ::File.file?(file)
    @config_file_loaded = true
    load file
  end
end
