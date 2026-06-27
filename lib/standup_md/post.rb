# frozen_string_literal: true

require "standup_md/post/message"
require "standup_md/post/result"
require "standup_md/post/adapter"
require "standup_md/post/adapters/slack"

module StandupMD
  ##
  # Namespace for posting standup entries to chat clients.
  module Post
    ##
    # Base error for posting failures.
    class Error < StandardError; end

    ##
    # Raised when a configured adapter cannot be found.
    class UnknownAdapter < Error; end
  end
end
