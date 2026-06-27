# frozen_string_literal: true

require "date"

module StandupMD
  class Config
    ##
    # The configuration class for StandupMD::Cli
    class Cli
      ##
      # The default options.
      #
      # @return [Hash]
      DEFAULTS = {
        date: -> { Date.today },
        editor: -> { ENV["VISUAL"] || ENV["EDITOR"] || "vim" },
        verbose: false,
        edit: true,
        write: true,
        print: false,
        post: false,
        post_adapter: nil,
        post_channel: nil,
        auto_fill_previous: true,
        preference_file: ::File.expand_path(
          ::File.join(ENV["HOME"], ".standuprc")
        )
      }.freeze

      ##
      # Attributes copied into request-scoped config snapshots.
      #
      # @return [Array<Symbol>]
      CONFIG_ATTRIBUTES = DEFAULTS.keys.freeze

      ##
      # The editor to use when opening standup files. If one is not set, the
      # first of $VISUAL, $EDITOR, or vim will be used, in that order.
      #
      # @param [String] editor
      #
      # @return [String]
      attr_accessor :editor

      ##
      # Should the CLI print verbose output?
      #
      # @param [Boolean] verbose
      #
      # @return [Boolean]
      attr_accessor :verbose

      ##
      # Should the CLI edit?
      #
      # @param [Boolean] edit
      #
      # @return [Boolean]
      attr_accessor :edit

      ##
      # Should the CLI automatically write the new entry to the file?
      #
      # @param [Boolean] write
      #
      # @return [Boolean]
      attr_accessor :write

      ##
      # Should the CLI print the entry to the command line?
      #
      # @param [Boolean] print
      #
      # @return [Boolean]
      attr_accessor :print

      ##
      # Should the CLI post the entry to a chat client?
      #
      # @param [Boolean] post
      #
      # @return [Boolean]
      attr_accessor :post

      ##
      # The chat adapter to use for posting.
      #
      # @param [String, Symbol, nil] post_adapter
      #
      # @return [String, Symbol, nil]
      attr_accessor :post_adapter

      ##
      # The channel to use for posting.
      #
      # @param [String, nil] post_channel
      #
      # @return [String, nil]
      attr_accessor :post_channel

      ##
      # The date to use to find the entry.
      #
      # @param [Date] date
      #
      # @return [Date]
      attr_accessor :date

      ##
      # The preference file for Cli.
      #
      # @param [String] preference
      #
      # @return [String]
      attr_accessor :preference_file

      ##
      # When writing a new entry, should 'previous' be pulled from the last
      # entry?
      #
      # @param [Boolean] auto_fill_previous
      #
      # @return [Boolean]
      attr_accessor :auto_fill_previous

      ##
      # Initializes the config with default values.
      def initialize
        reset
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Hash]
      def reset
        DEFAULTS.each do |key, value|
          instance_variable_set("@#{key}", copy_default(resolve_default(value)))
        end
      end

      ##
      # Copies values from another CLI config.
      #
      # @param [StandupMD::Config::Cli] config
      #
      # @return [StandupMD::Config::Cli]
      def copy_from(config)
        CONFIG_ATTRIBUTES.each do |attribute|
          instance_variable_set(
            "@#{attribute}",
            copy_default(config.public_send(attribute))
          )
        end
        self
      end

      private

      def resolve_default(value)
        value.respond_to?(:call) ? value.call : value
      end

      def copy_default(value)
        return value.dup if value.is_a?(Array) || value.is_a?(Hash)

        value
      end
    end
  end
end
