# frozen_string_literal: true

require "date"

module StandupMD
  ##
  # The title for a standup entry.
  class Title
    ##
    # The entry date.
    #
    # @return [Date]
    attr_reader :date

    ##
    # Constructs an instance of +StandupMD::Title+.
    #
    # @param [Date] date
    def initialize(date)
      raise ArgumentError, "Must be a Date object" unless date.is_a?(Date)

      @date = date
    end

    ##
    # The configured title text.
    #
    # @return [String]
    def to_s
      date.strftime(StandupMD.config.file.header_date_format)
    end

    ##
    # The title rendered as markdown.
    #
    # @return [String]
    def to_markdown
      "#" * StandupMD.config.file.header_depth + " " + to_s
    end
  end
end
