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
    # @param config [StandupMD::Config]
    #
    # @return [StandupMD::Post::Result]
    def post(entry, adapter: nil, channel: nil, text: nil, renderer: nil, config: StandupMD.config)
      adapter_name = (adapter || config.post.default_adapter).to_sym
      message = Message.new(
        entry: entry,
        text: text || (renderer || default_renderer(config)).render_entry(entry),
        channel: channel,
        adapter: adapter_name
      )
      config.post.build_adapter(adapter_name).post(message)
    end

    ##
    # Default renderer used when posting an entry.
    #
    # @param config [StandupMD::Config]
    #
    # @return [StandupMD::Parsers::Markdown]
    def default_renderer(config = StandupMD.config)
      StandupMD::Parsers::Markdown.new(config.file)
    end
  end
end
