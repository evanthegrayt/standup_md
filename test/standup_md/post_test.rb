# frozen_string_literal: true

require_relative "../test_helper"

class TestPost < TestHelper
  class RecordingAdapter
    class << self
      attr_accessor :messages
    end

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def post(message)
      self.class.messages << [message, options]
      StandupMD::Post::Result.success(
        adapter: message.adapter,
        channel: message.channel || options[:channel]
      )
    end
  end

  def setup
    super
    RecordingAdapter.messages = []
    StandupMD.config.file.reset
    StandupMD.config.post.reset
  end

  def teardown
    super
    StandupMD.config.file.reset
    StandupMD.config.post.reset
  end

  def test_message
    entry = StandupMD::Entry.create
    message = StandupMD::Post::Message.new(
      entry: entry,
      text: "# #{Date.today}",
      channel: "C123",
      adapter: "slack"
    )

    assert_equal(entry, message.entry)
    assert_equal("# #{Date.today}", message.text)
    assert_equal("C123", message.channel)
    assert_equal(:slack, message.adapter)
  end

  def test_result_success
    result = StandupMD::Post::Result.success(
      adapter: :slack,
      channel: "C123",
      response: {"ok" => true}
    )

    assert(result.success?)
    refute(result.failure?)
    assert_equal(:slack, result.adapter)
    assert_equal("C123", result.channel)
    assert_equal({"ok" => true}, result.response)
  end

  def test_result_failure
    result = StandupMD::Post::Result.failure(
      adapter: "slack",
      channel: "C123",
      error: "channel_not_found"
    )

    refute(result.success?)
    assert(result.failure?)
    assert_equal(:slack, result.adapter)
    assert_equal("channel_not_found", result.error)
  end

  def test_adapter_base_class_requires_post_implementation
    adapter = StandupMD::Post::Adapter.new

    assert_raise(NotImplementedError) do
      adapter.post(nil)
    end
  end

  def test_post_entry
    StandupMD.config.post.register_adapter(:test, RecordingAdapter)
    StandupMD.config.post.configure_adapter(:test, channel: "configured")
    entry = StandupMD::Entry.new(
      Date.today,
      ["Current task"],
      ["Previous task"],
      ["Impediment"]
    )

    result = StandupMD::Post.post(entry, adapter: :test, channel: "runtime")

    assert(result.success?)
    assert_equal(:test, result.adapter)
    assert_equal("runtime", result.channel)
    message, options = RecordingAdapter.messages.first
    assert_equal(entry, message.entry)
    assert_equal(:test, message.adapter)
    assert_equal("runtime", message.channel)
    assert_equal({channel: "configured"}, options)
    assert_match(/# #{Date.today.strftime(StandupMD.config.file.header_date_format)}/, message.text)
    assert_match(/\n- Current task\n/, message.text)
  end

  def test_post_entry_applies_configured_title
    StandupMD.config.post.register_adapter(:test, RecordingAdapter)
    StandupMD.config.post.title = "%s - Evan Gray"
    entry = StandupMD::Entry.new(
      Date.new(2026, 6, 27),
      ["Current task"],
      ["Previous task"],
      []
    )

    StandupMD::Post.post(entry, adapter: :test)

    message, = RecordingAdapter.messages.first
    assert_equal("# 2026-06-27 - Evan Gray", message.text.lines.first.chomp)
    assert_match(/\n## Current\n- Current task\n/, message.text)
  end

  def test_post_entry_title_uses_configured_date_format
    StandupMD.config.file.header_date_format = "%m/%d/%Y"
    StandupMD.config.post.register_adapter(:test, RecordingAdapter)
    StandupMD.config.post.title = "%s - Evan Gray"
    entry = StandupMD::Entry.new(
      Date.new(2026, 6, 27),
      ["Current task"],
      [],
      []
    )

    StandupMD::Post.post(entry, adapter: :test)

    message, = RecordingAdapter.messages.first
    assert_equal("# 06/27/2026 - Evan Gray", message.text.lines.first.chomp)
  end

  def test_post_entry_uses_default_adapter
    StandupMD.config.post.default_adapter = :test
    StandupMD.config.post.register_adapter(:test, RecordingAdapter)

    StandupMD::Post.post(StandupMD::Entry.create, channel: "runtime")

    message, = RecordingAdapter.messages.first
    assert_equal(:test, message.adapter)
  end

  def test_post_entry_accepts_runtime_config
    runtime = StandupMD.config.copy
    runtime.file.current_header = "Today"
    runtime.post.title = "%s - Evan Gray"
    runtime.post.default_adapter = :test
    runtime.post.register_adapter(:test, RecordingAdapter)
    runtime.post.configure_adapter(:test, channel: "runtime-config")

    StandupMD::Post.post(StandupMD::Entry.create, config: runtime)

    message, options = RecordingAdapter.messages.first
    assert_equal(:test, message.adapter)
    assert_match(/\A# .+ - Evan Gray/, message.text)
    assert_match(/## Today/, message.text)
    assert_equal({channel: "runtime-config"}, options)
    assert_equal("Current", StandupMD.config.file.current_header)
    assert_equal(:slack, StandupMD.config.post.default_adapter)
    assert_nil(StandupMD.config.post.title)
  end

  def test_post_entry_allows_pre_rendered_text
    StandupMD.config.post.register_adapter(:test, RecordingAdapter)
    StandupMD.config.post.title = "%s - Evan Gray"
    entry = StandupMD::Entry.create

    StandupMD::Post.post(entry, adapter: :test, text: "custom body")

    message, = RecordingAdapter.messages.first
    assert_equal("custom body", message.text)
  end
end
