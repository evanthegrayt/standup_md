# frozen_string_literal: true

require "json"
require "standup_md/section"

module StandupMD
  ##
  # Class for handling single entries. Includes the comparable module, and
  # compares by date.
  class Entry
    include Comparable

    SECTION_TYPES = %i[current previous impediments notes].freeze

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
    # Creates a generic entry. Default values can be set via configuration.
    # Yields the entry if a block is passed so you can change values.
    #
    # @return [StandupMD::Entry]
    def self.create
      new(
        Date.today,
        config.current,
        config.previous,
        config.impediments,
        config.notes
      ).tap { |entry| yield entry if block_given? }
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
      @date = date
      @sections = {}
      self.current = current
      self.previous = previous
      self.impediments = impediments
      self.notes = notes
    end

    SECTION_TYPES.each do |type|
      define_method(type) do
        section(type).tasks.map(&:to_s)
      end

      define_method("#{type}=") do |tasks|
        set_section(type, tasks)
      end

      define_method("#{type}_tasks") do
        section(type).tasks
      end
    end

    ##
    # Sections for this entry.
    #
    # @return [Array<StandupMD::Section>]
    def sections
      SECTION_TYPES.map { |type| section(type) }
    end

    ##
    # Find a section by type.
    #
    # @param [Symbol, String] type
    #
    # @return [StandupMD::Section]
    def section(type)
      @sections[type.to_sym] ||= Section.new(type)
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
          "current" => current,
          "previous" => previous,
          "impediments" => impediments,
          "notes" => notes
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

    private

    def set_section(type, tasks)
      @sections[type.to_sym] = Section.new(type, tasks || [])
    end
  end
end
