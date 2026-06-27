# frozen_string_literal: true

module StandupMD
  module Post
    ##
    # Base class for chat posting adapters.
    class Adapter
      ##
      # Adapter-specific non-secret options.
      #
      # @return [Hash]
      attr_reader :options

      ##
      # Creates an adapter.
      #
      # @param options [Hash]
      def initialize(options = {})
        @options = symbolize_keys(options)
      end

      ##
      # Sends a message.
      #
      # @param message [StandupMD::Post::Message]
      #
      # @return [StandupMD::Post::Result]
      def post(message)
        raise NotImplementedError, "#{self.class} must implement #post"
      end

      private

      def symbolize_keys(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[key.to_sym] = value
        end
      end
    end
  end
end
