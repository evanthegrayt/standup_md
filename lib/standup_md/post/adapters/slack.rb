# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "standup_md/post/adapter"
require "standup_md/post/result"

module StandupMD
  module Post
    ##
    # Namespace for built-in posting adapters.
    module Adapters
      ##
      # Posts standup entries to Slack using the chat.postMessage Web API.
      class Slack < StandupMD::Post::Adapter
        ##
        # Slack chat.postMessage endpoint.
        #
        # @return [String]
        DEFAULT_ENDPOINT = "https://slack.com/api/chat.postMessage"

        ##
        # Environment variable used for the Slack token by default.
        #
        # @return [String]
        DEFAULT_TOKEN_ENV = "STANDUP_MD_SLACK_TOKEN"

        ##
        # Sends a message to Slack.
        #
        # @param message [StandupMD::Post::Message]
        #
        # @return [StandupMD::Post::Result]
        def post(message)
          channel = message.channel || options[:channel]
          token = ENV[token_env]
          return failure(message, channel, "No Slack channel configured") if blank?(channel)
          return failure(message, channel, "Missing Slack token in $#{token_env}") if blank?(token)

          response = perform_request(channel, message.text, token)
          parsed = parse_response(response.body)
          return success(message, channel, response, parsed) if response.is_a?(Net::HTTPSuccess) && parsed["ok"]

          failure(message, channel, error_message(response, parsed), parsed)
        rescue => e
          failure(message, channel, e.message)
        end

        private

        def endpoint
          options[:endpoint] || DEFAULT_ENDPOINT
        end

        def token_env
          options[:token_env] || DEFAULT_TOKEN_ENV
        end

        def perform_request(channel, text, token)
          uri = URI(endpoint)
          request = Net::HTTP::Post.new(uri)
          request["Authorization"] = "Bearer #{token}"
          request["Content-Type"] = "application/json; charset=utf-8"
          request["Accept"] = "application/json"
          request.body = JSON.generate(channel: channel, text: text)

          return options[:http].call(request, uri) if options[:http]

          Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(request)
          end
        end

        def parse_response(body)
          JSON.parse(body.to_s)
        rescue JSON::ParserError
          {}
        end

        def success(message, channel, http_response, parsed)
          StandupMD::Post::Result.success(
            adapter: message.adapter,
            channel: channel,
            response: parsed.merge("code" => http_response.code)
          )
        end

        def failure(message, channel, error, response = {})
          StandupMD::Post::Result.failure(
            adapter: message.adapter,
            channel: channel,
            error: error,
            response: response
          )
        end

        def error_message(http_response, parsed)
          parsed["error"] || "Slack returned HTTP #{http_response.code}"
        end

        def blank?(value)
          value.nil? || value.to_s.empty?
        end
      end
    end
  end
end
