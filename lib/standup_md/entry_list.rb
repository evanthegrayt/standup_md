# frozen_string_literal: true

require 'forwardable'

module StandupMD
  ##
  # Enumerable list of entries.
  class EntryList
    extend Forwardable
    include Enumerable

    ##
    # Access to the class's configuration.
    #
    # @return [StandupMD::Config::EntryList]
    def self.config
      @config ||= StandupMD.config.entry_list
    end

    ##
    # Contruct a list. Can pass any amount of +StandupMD::Entry+ instances.
    #
    # @param [Entry] entries
    #
    # @return [StandupMD::EntryList]
    def initialize(*entries)
      @config = self.class.config
      unless entries.all? { |e| e.is_a?(StandupMD::Entry) }
        raise ArgumentError, 'Entry must instance of StandupMD::Entry'
      end
      @entries = entries
    end

    ##
    # Appends entries to list.
    #
    # @param [StandupMD::Entry] entry
    #
    # @return [Array]
    def <<(entry)
      unless entry.is_a?(StandupMD::Entry)
        raise ArgumentError, 'Entry must instance of StandupMD::Entry'
      end
      @entries << entry
    end

    ##
    # Finds an entry based on date. This method assumes the list has already
    # been sorted.
    #
    # @param [Date] date
    #
    # @return [StandupMD::Entry]
    def find(date)
      entries.bsearch { |e| e.date == date }
    end

    ##
    # Returns a copy of self sorted by date.
    #
    # @return [StandupMD::EntryList]
    def sort
      self.class.new(*@entries.sort)
    end

    ##
    # Replace entries with sorted entries by date.
    #
    # @return [StandupMD::EntryList]
    def sort!
      @entries = @entries.sort
      self
    end

    ##
    # Returns a copy of self sorted by date.
    #
    # @return [StandupMD::EntryList]
    def sort_reverse
      self.class.new(*@entries.sort.reverse)
    end

    ##
    # Returns entries that are between the start and end date. This method
    # assumes the list has already been sorted.
    #
    # @param [Date] start_date
    #
    # @param [Date] end_date
    #
    # @return [Array]
    def filter(start_date, end_date)
      self.class.new(
        *@entries.select { |e| e.date.between?(start_date, end_date) }
      )
    end

    ##
    # Replaces entries with results of filter.
    #
    # @param [Date] start_date
    #
    # @param [Date] end_date
    #
    # @return [Array]
    def filter!(start_date, end_date)
      @entries = filter(start_date, end_date)
      self
    end

    ##
    # The list as a hash, with the dates as keys.
    #
    # @return [Hash]
    def to_h
      Hash[@entries.map { |e| [e.date, {
        'current'     => e.current,
        'previous'    => e.previous,
        'impediments' => e.impediments,
        'notes'       => e.notes
      }]}]
    end

    ##
    # The entry list as a json object.
    #
    # @return [String]
    def to_json
      to_h.to_json
    end

    # :section: Delegators

    ##
    # The following are forwarded to @entries, which is the underly array of
    # entries.
    #
    # +each+:: Iterate over each entry.
    #
    # +empty?+:: Is the list empty?
    #
    # +size+:: How many items are in the list?
    #
    # +first+:: The first record in the list.
    #
    # +last+:: The last record in the list.
    def_delegators :@entries, :each, :empty?, :size, :first, :last
  end
end
