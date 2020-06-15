# frozen_string_literal: true

require 'json'

module StandupMD

  ##
  # Class for handling single entries. Includes the comparable module, and
  # compares by date.
  class Entry
    include Comparable

    ##
    # Access to the class's configuration.
    #
    # @return [StandupMD::Config::Entry]
    def self.config
      @config ||= StandupMD.config.entry
    end

    ##
    # The date of the entry.
    #
    # @param [Date] date
    #
    # @return [Date]
    attr_accessor :date

    ##
    # The tasks for today.
    #
    # @return [Array]
    attr_accessor :current

    ##
    # The tasks from the previous day.
    #
    # @return [Array]
    attr_accessor :previous

    ##
    # Iimpediments for this entry.
    #
    # @return [Array]
    attr_accessor :impediments

    ##
    # Nnotes to add to this entry.
    #
    # @return [Array]
    attr_accessor :notes

    ##
    # Creates a generic entry. Default values can be set via configuration.
    # Yields the entry if a block is passed so you can change values.
    #
    # @return [StandupMD::Entry]
    def self.create
      entry = new(
        Date.today,
        config.current,
        config.previous,
        config.impediments,
        config.notes
      )
      yield config if block_given?
      entry
    end

    ##
    # Constructs instance of +StandupMD::Entry+.
    #
    # @param [Date] date
    #
    # @param [Array] current
    #
    # @param [Array] previous
    #
    # @param [Array] impediments
    #
    # @param [Array] notes
    def initialize(date, current, previous, impediments, notes = [])
      raise unless date.is_a?(Date)
      @config = self.class.config

      @date           = date
      @current        = current
      @previous       = previous
      @impediments    = impediments
      @notes          = notes
    end

    ##
    # Sorting method for Comparable. Entries are compared by date.
    def <=>(other)
      date <=> other.date
    end

    ##
    # Entry as a hash .
    #
    # @return [Hash]
    def to_h
      {
        date => {
          'current'     => current,
          'previous'    => previous,
          'impediments' => impediments,
          'notes'       => notes
        }
      }
    end

    ##
    # Entry as a json object.
    #
    # @return [String]
    def to_json
      to_h.to_json
    end
  end
end
