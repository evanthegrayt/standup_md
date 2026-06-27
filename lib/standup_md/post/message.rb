# frozen_string_literal: true

module StandupMD
  module Post
    ##
    # A platform-neutral message to send through a posting adapter.
    class Message
      ##
      # The standup entry being posted.
      #
      # @return [StandupMD::Entry]
      attr_reader :entry

      ##
      # The rendered message body.
      #
      # @return [String]
      attr_reader :text

      ##
      # The destination channel, room, or conversation identifier.
      #
      # @return [String, nil]
      attr_reader :channel

      ##
      # The adapter name requested by the user.
      #
      # @return [Symbol]
      attr_reader :adapter

      ##
      # Builds a message for a posting adapter.
      #
      # @param entry [StandupMD::Entry]
      # @param text [String]
      # @param channel [String, nil]
      # @param adapter [String, Symbol]
      def initialize(entry:, text:, channel:, adapter:)
        @entry = entry
        @text = text.to_s
        @channel = channel
        @adapter = adapter.to_sym
      end
    end
  end
end
