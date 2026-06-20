# frozen_string_literal: true

module StandupMD
  ##
  # A single standup task. The text stays format-neutral, while indentation
  # level lets parsers render nested tasks for their own formats.
  class Task
    ##
    # The task text.
    #
    # @return [String]
    attr_reader :text

    ##
    # The nesting level of the task.
    #
    # @return [Integer]
    attr_reader :indent_level

    ##
    # Constructs an instance of +StandupMD::Task+.
    #
    # @param [String] text
    # @param [Integer] indent_level
    def initialize(text, indent_level: 0)
      unless indent_level.is_a?(Integer) && !indent_level.negative?
        raise ArgumentError, "Indent level must be a non-negative integer"
      end

      @text = text.to_s
      @indent_level = indent_level
    end

    ##
    # The format-neutral task text.
    #
    # @return [String]
    def to_s
      text
    end

    ##
    # The task rendered as a markdown list item.
    #
    # @return [String]
    def to_markdown
      indent = " " * StandupMD.config.file.indent_width * indent_level
      "#{indent}#{StandupMD.config.file.bullet_character} #{text}"
    end

    ##
    # Compares task contents.
    def ==(other)
      return text == other if other.is_a?(String)
      return false unless other.is_a?(Task)

      text == other.text && indent_level == other.indent_level
    end
  end
end
