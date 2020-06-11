# frozen_string_literal: true
require 'date'

module StandupMD
  class Config

    ##
    # The configuration class for StandupMD::Cli
    class Cli
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
      # Should the cli write the file?
      #
      # @param [Boolean] write
      #
      # @return [Boolean]
      attr_accessor :write

      ##
      # Should the cli print the entry?
      #
      # @param [Boolean] print
      #
      # @return [Boolean]
      attr_accessor :print

      ##
      # The date to use to find the file.
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
        reset_values
      end

      ##
      # Sets all config values back to their defaults.
      #
      # @return [Boolean] true if successful
      def reset_values
        @date = Date.today
        @editor = set_editor
        @verbose = false
        @edit = true
        @write = true
        @print = false
        @auto_fill_previous = true
        @preference_file = ::File.expand_path(::File.join(ENV['HOME'], '.standuprc'))
      end

      private

      def set_editor # :nodoc:
        return ENV['VISUAL'] if ENV['VISUAL']
        return ENV['EDITOR'] if ENV['EDITOR']
        'vim'
      end
    end
  end
end
