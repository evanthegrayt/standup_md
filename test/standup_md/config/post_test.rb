# frozen_string_literal: true

require_relative "../../test_helper"

class TestPostConfig < TestHelper
  class OptionAdapter
    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def post(_message)
      StandupMD::Post::Result.success(adapter: :option, channel: nil)
    end
  end

  def setup
    super
    StandupMD.config.post.reset
  end

  def teardown
    super
    StandupMD.config.post.reset
  end

  def test_reset
    StandupMD.config.post.default_adapter = :teams
    StandupMD.config.post.title = "%s - Test"
    StandupMD.config.post.register_adapter(:teams, OptionAdapter)
    StandupMD.config.post.reset

    assert_equal(:slack, StandupMD.config.post.default_adapter)
    assert_nil(StandupMD.config.post.title)
    assert_equal(
      StandupMD::Post::Adapters::Slack,
      StandupMD.config.post.adapters[:slack]
    )
    refute(StandupMD.config.post.adapters.key?(:teams))
  end

  def test_title
    assert_nil(StandupMD.config.post.title)
    assert_nothing_raised { StandupMD.config.post.title = "%s - Evan Gray" }
    assert_equal("%s - Evan Gray", StandupMD.config.post.title)
  end

  def test_copy_from_copies_title
    StandupMD.config.post.title = "%s - Evan Gray"
    copy = StandupMD.config.post.class.new.copy_from(StandupMD.config.post)

    assert_equal("%s - Evan Gray", copy.title)
  end

  def test_configure_adapter
    StandupMD.config.post.configure_adapter(
      "slack",
      "channel" => "C123",
      "token_env" => "SLACK_TOKEN"
    )

    assert_equal(
      {channel: "C123", token_env: "SLACK_TOKEN"},
      StandupMD.config.post.options_for(:slack)
    )
  end

  def test_register_and_build_adapter
    StandupMD.config.post.register_adapter(:option, OptionAdapter)
    StandupMD.config.post.configure_adapter(:option, channel: "C123")

    adapter = StandupMD.config.post.build_adapter(:option)

    assert_instance_of(OptionAdapter, adapter)
    assert_equal({channel: "C123"}, adapter.options)
  end

  def test_build_unknown_adapter
    assert_raise(StandupMD::Post::UnknownAdapter) do
      StandupMD.config.post.build_adapter(:teams)
    end
  end
end
