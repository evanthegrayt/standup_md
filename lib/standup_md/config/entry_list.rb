# frozen_string_literal: true

module StandupMD
  class Config
    ##
    # The configuration class for StandupMD::EntryList
    class EntryList
      ##
      # The default options.
      #
      # @return [Hash]
      DEFAULTS = {}.freeze

      ##
      # Initializes the config with default values.
      def initalize
        reset
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Hash]
      def reset
        DEFAULTS.each { |k, v| instance_variable_set("@#{k}", v) }
      end
    end
  end
end
