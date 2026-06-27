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
      # Attributes copied into request-scoped config snapshots.
      #
      # @return [Array<Symbol>]
      CONFIG_ATTRIBUTES = DEFAULTS.keys.freeze

      ##
      # Initializes the config with default values.
      def initialize
        reset
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Hash]
      def reset
        DEFAULTS.each { |k, v| instance_variable_set("@#{k}", v) }
      end

      ##
      # Copies values from another entry list config.
      #
      # @param [StandupMD::Config::EntryList] config
      #
      # @return [StandupMD::Config::EntryList]
      def copy_from(config)
        CONFIG_ATTRIBUTES.each do |attribute|
          instance_variable_set("@#{attribute}", config.public_send(attribute))
        end
        self
      end
    end
  end
end
