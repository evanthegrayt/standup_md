# frozen_string_literal: true

require "json"
require_relative "../../test_helper"

class TestSlackPostAdapter < TestHelper
  def setup
    super
    @original_token = ENV["STANDUP_MD_SLACK_TOKEN"]
    @message = StandupMD::Post::Message.new(
      entry: StandupMD::Entry.create,
      text: "# Standup\n## Current\n- Build adapters\n",
      channel: "C123",
      adapter: :slack
    )
  end

  def teardown
    if @original_token.nil?
      ENV.delete("STANDUP_MD_SLACK_TOKEN")
    else
      ENV["STANDUP_MD_SLACK_TOKEN"] = @original_token
    end
    super
  end

  def test_missing_token
    ENV.delete("STANDUP_MD_SLACK_TOKEN")
    adapter = StandupMD::Post::Adapters::Slack.new(channel: "C123")

    result = adapter.post(@message)

    refute(result.success?)
    assert_equal("Missing Slack token in $STANDUP_MD_SLACK_TOKEN", result.error)
  end

  def test_missing_channel
    ENV["STANDUP_MD_SLACK_TOKEN"] = "secret"
    adapter = StandupMD::Post::Adapters::Slack.new
    message = StandupMD::Post::Message.new(
      entry: StandupMD::Entry.create,
      text: "hello",
      channel: nil,
      adapter: :slack
    )

    result = adapter.post(message)

    refute(result.success?)
    assert_equal("No Slack channel configured", result.error)
  end

  def test_successful_post
    ENV["STANDUP_MD_SLACK_TOKEN"] = "secret"
    request = {}
    http = fake_http(request, body: '{"ok":true,"channel":"C123","ts":"1.000"}')

    adapter = StandupMD::Post::Adapters::Slack.new(http: http)
    result = adapter.post(@message)

    assert(result.success?)
    assert_equal("C123", result.channel)
    assert_equal("Bearer secret", request[:headers]["authorization"])
    assert_match(%r{application/json}, request[:headers]["content-type"])
    assert_equal(
      {"channel" => "C123", "text" => @message.text},
      JSON.parse(request[:body])
    )
  end

  def test_adapter_config_channel_is_used_when_message_channel_is_nil
    ENV["STANDUP_MD_SLACK_TOKEN"] = "secret"
    message = StandupMD::Post::Message.new(
      entry: StandupMD::Entry.create,
      text: "hello",
      channel: nil,
      adapter: :slack
    )

    request = {}
    http = fake_http(request, body: '{"ok":true,"channel":"C999","ts":"1.000"}')
    adapter = StandupMD::Post::Adapters::Slack.new(
      http: http,
      channel: "C999"
    )

    result = adapter.post(message)

    assert(result.success?)
    assert_equal("C999", JSON.parse(request[:body])["channel"])
  end

  def test_slack_api_error
    ENV["STANDUP_MD_SLACK_TOKEN"] = "secret"
    http = fake_http({}, body: '{"ok":false,"error":"channel_not_found"}')

    adapter = StandupMD::Post::Adapters::Slack.new(http: http)
    result = adapter.post(@message)

    refute(result.success?)
    assert_equal("channel_not_found", result.error)
  end

  def test_http_error
    ENV["STANDUP_MD_SLACK_TOKEN"] = "secret"
    http = fake_http({}, code: "500", message: "Internal Server Error", body: "{}")

    adapter = StandupMD::Post::Adapters::Slack.new(http: http)
    result = adapter.post(@message)

    refute(result.success?)
    assert_equal("Slack returned HTTP 500", result.error)
  end

  private

  def fake_http(captured, body:, code: "200", message: "OK")
    lambda do |request, uri|
      captured[:uri] = uri
      captured[:body] = request.body
      captured[:headers] = request.to_hash.transform_values(&:first)
      fake_response(code, message, body)
    end
  end

  def fake_response(code, message, body)
    response_class = Net::HTTPResponse::CODE_TO_OBJ.fetch(code)
    response = response_class.new("1.1", code, message)
    response.instance_variable_set(:@read, true)
    response.body = body
    response
  end
end
