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
        text: text || render_post_text(entry, renderer, config),
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

    ##
    # Renders text for a posted entry.
    #
    # @param entry [StandupMD::Entry]
    # @param renderer [Object, nil]
    # @param config [StandupMD::Config]
    #
    # @return [String]
    def render_post_text(entry, renderer, config)
      text = (renderer || default_renderer(config)).render_entry(entry)
      apply_post_title(text, entry, config)
    end

    ##
    # Applies the configured post title format to the first entry header.
    #
    # @param text [String]
    # @param entry [StandupMD::Entry]
    # @param config [StandupMD::Config]
    #
    # @return [String]
    def apply_post_title(text, entry, config)
      return text unless config.post.title

      title = config.post.title % entry.date.strftime(config.file.header_date_format)
      header = "#" * config.file.header_depth
      text.sub(/\A#{Regexp.escape(header)}\s+.*$/, "#{header} #{title}")
    end
  end
end
