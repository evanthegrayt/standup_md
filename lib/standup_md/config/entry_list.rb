# frozen_string_literal: true

module StandupMD
  class Config

    ##
    # The configuration class for StandupMD::EntryList
    class EntryList

      ##
      # Initializes the config with default values.
      def initalize
        reset_values
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Boolean] true if successful
      def reset_values
        # TODO add order ascending or decending.
        true
      end
    end
  end
end
