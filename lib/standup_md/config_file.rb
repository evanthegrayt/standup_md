# frozen_string_literal: true

module StandupMD
  class ConfigFile
    ##
    # The name of the instantiated config file.
    attr_reader :name

    ##
    # @param [String] file_name
    def initialize(name)
      @name = ::File.expand_path(name)
      raise "File #{@name} does not exist." unless ::File.file?(@name)
      @loaded = false
    end

    ##
    # Has the config file been loaded?
    #
    # @return [Boolean]
    def loaded?
      @loaded
    end

    ##
    # Loads the config file.
    #
    # @return [Boolean] Was the file loaded?
    def load
      @loaded = load @file
    end
  end
end
