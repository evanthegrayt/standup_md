# frozen_string_literal: true

module StandupMD
  class Config
    ##
    # The configuration class for StandupMD::Entry
    class Entry
      ##
      # The default options.
      #
      # @return [Hash]
      DEFAULTS = {
        current: ["<!-- ADD TODAY'S WORK HERE -->"],
        previous: [],
        impediments: ["None"],
        notes: []
      }.freeze

      ##
      # Attributes copied into request-scoped config snapshots.
      #
      # @return [Array<Symbol>]
      CONFIG_ATTRIBUTES = DEFAULTS.keys.freeze

      ##
      # Tasks for "Current" section.
      #
      # @param [Array] current
      #
      # @return [Array]
      attr_accessor :current

      ##
      # Tasks for "Previous" section.
      #
      # @param [Array] previous
      #
      # @return [Array]
      attr_accessor :previous

      ##
      # Impediments for this entry.
      #
      # @param [Array] impediments
      #
      # @return [Array]
      attr_accessor :impediments

      ##
      # Notes for this entry.
      #
      # @param [Array] notes
      #
      # @return [Array]
      attr_accessor :notes

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
        DEFAULTS.each { |k, v| instance_variable_set("@#{k}", copy_default(v)) }
      end

      ##
      # Copies values from another entry config.
      #
      # @param [StandupMD::Config::Entry] config
      #
      # @return [StandupMD::Config::Entry]
      def copy_from(config)
        CONFIG_ATTRIBUTES.each do |attribute|
          instance_variable_set(
            "@#{attribute}",
            copy_default(config.public_send(attribute))
          )
        end
        self
      end

      private

      def copy_default(value)
        return value.dup if value.is_a?(Array) || value.is_a?(Hash)

        value
      end
    end
  end
end
