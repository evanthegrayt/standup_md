# frozen_string_literal: true

module StandupMD
  class Config

    ##
    # The configuration class for StandupMD::Entry
    class Entry

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
        reset_values
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Boolean] true if successful
      def reset_values
        @current = ["<!-- ADD TODAY'S WORK HERE -->"]
        @previous = []
        @impediments = ['None']
        @notes = []
        true
      end
    end
  end
end
