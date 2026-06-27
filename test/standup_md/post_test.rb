# frozen_string_literal: true

require_relative "../test_helper"

class TestPost < TestHelper
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
end
