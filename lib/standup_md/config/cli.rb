# frozen_string_literal: true
require 'date'

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
        date: Date.today,
        editor: ENV['VISUAL'] || ENV['EDITOR'] || 'vim',
        verbose: false,
        edit: true,
        write: true,
        print: false,
        auto_fill_previous: true,
        preference_file:
          ::File.expand_path(::File.join(ENV['HOME'], '.standuprc')),
      }

      ##
      # The editor to use when opening standup files. If one is not set, the
      # first of $VISUAL, $EDITOR, or vim will be used, in that order.
      #
      # @param [String] editor
      #
      # @return [String]
      attr_accessor :editor

      ##
      # Should the cli print verbose output?
      #
      # @param [Boolean] verbose
      #
      # @return [Boolean]
      attr_accessor :verbose

      ##
      # Should the cli edit?
      #
      # @param [Boolean] edit
      #
      # @return [Boolean]
      attr_accessor :edit

      ##
      # Should the cli automatically write the new entry to the file?
      #
      # @param [Boolean] write
      #
      # @return [Boolean]
      attr_accessor :write

      ##
      # Should the cli print the entry to the command line?
      #
      # @param [Boolean] print
      #
      # @return [Boolean]
      attr_accessor :print

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
        DEFAULTS.each { |k, v| instance_variable_set("@#{k}", v) }
      end
    end
  end
end
