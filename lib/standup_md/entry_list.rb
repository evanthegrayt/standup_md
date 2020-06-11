# frozen_string_literal: true

module StandupMD

  ##
  # Enumerable list of entries.
  class EntryList
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
    # Iterate over the list and yield each entry.
    def each(&block)
      @entries.each(&block)
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
    def find(key)
      to_a.bsearch { |e| e.date == key }
    end

    ##
    # How many entries are in the list.
    #
    # @return [Integer]
    def size
      @entries.size
    end

    ##
    # Is the list empty?
    #
    # @return [Boolean] true if empty
    def empty?
      @entries.empty?
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
    # The first entry in the list. This method assumes the list has
    # already been sorted.
    #
    # @return [StandupMD::Entry]
    def first
      to_a.first
    end

    ##
    # The last entry in the list. This method assumes the list has
    # already been sorted.
    #
    # @return [StandupMD::Entry]
    def last
      to_a.last
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
  end
end
