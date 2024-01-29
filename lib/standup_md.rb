# frozen_string_literal: true

require_relative "standup_md/version"
require_relative "standup_md/file"
require_relative "standup_md/entry"
require_relative "standup_md/entry_list"
require_relative "standup_md/cli"
require_relative "standup_md/config"

##
# The main module for the gem. Provides access to configuration classes.
module StandupMD
  module_function

  ##
  # Method for accessing the configuration.
  #
  # @return [StanupMD::Config]
  def config
    @config || reset_config
  end

  ##
  # Reset all configuration values to their defaults.
  #
  # @return [StandupMD::Config]
  def reset_config
    @config = StandupMD::Config.new
  end

  ##
  # Allows for configuration via a block. Useful when making config files.
  #
  # @example
  #   StandupMD.configure { |s| s.cli.editor = 'mate' }
  def configure
    yield config
  end
end
