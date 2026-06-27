# frozen_string_literal: true

module StandupMD
  module Post
    ##
    # Result returned by posting adapters.
    class Result
      ##
      # The adapter that handled the post.
      #
      # @return [Symbol]
      attr_reader :adapter

      ##
      # The destination channel, room, or conversation identifier.
      #
      # @return [String, nil]
      attr_reader :channel

      ##
      # Adapter-specific response metadata.
      #
      # @return [Hash]
      attr_reader :response

      ##
      # Human-readable error message for failed posts.
      #
      # @return [String, nil]
      attr_reader :error

      ##
      # Builds a posting result.
      #
      # @param success [Boolean]
      # @param adapter [String, Symbol]
      # @param channel [String, nil]
      # @param response [Hash]
      # @param error [String, nil]
      def initialize(success:, adapter:, channel:, response: {}, error: nil)
        @success = success
        @adapter = adapter.to_sym
        @channel = channel
        @response = response
        @error = error
      end

      ##
      # Builds a successful result.
      #
      # @return [StandupMD::Post::Result]
      def self.success(adapter:, channel:, response: {})
        new(success: true, adapter: adapter, channel: channel, response: response)
      end

      ##
      # Builds a failed result.
      #
      # @return [StandupMD::Post::Result]
      def self.failure(adapter:, channel:, error:, response: {})
        new(
          success: false,
          adapter: adapter,
          channel: channel,
          response: response,
          error: error
        )
      end

      ##
      # Was the post successful?
      #
      # @return [Boolean]
      def success?
        @success
      end

      ##
      # Did the post fail?
      #
      # @return [Boolean]
      def failure?
        !success?
      end
    end
  end
end
