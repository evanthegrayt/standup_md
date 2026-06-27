# frozen_string_literal: true

require "standup_md/post/message"
require "standup_md/post/result"
require "standup_md/post/adapter"
require "standup_md/post/adapters/slack"
require "standup_md/parsers/markdown"

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

    module_function

    ##
    # Renders and posts a standup entry through a configured chat adapter.
    #
    # @param entry [StandupMD::Entry]
    # @param adapter [String, Symbol, nil]
    # @param channel [String, nil]
    # @param text [String, nil]
    # @param renderer [Object, nil]
    #
    # @return [StandupMD::Post::Result]
    def post(entry, adapter: nil, channel: nil, text: nil, renderer: nil)
      adapter_name = (adapter || StandupMD.config.post.default_adapter).to_sym
      message = Message.new(
        entry: entry,
        text: text || (renderer || default_renderer).render_entry(entry),
        channel: channel,
        adapter: adapter_name
      )
      StandupMD.config.post.build_adapter(adapter_name).post(message)
    end

    def default_renderer
      StandupMD::Parsers::Markdown.new(StandupMD.config.file)
    end
  end
end
