# frozen_string_literal: true

require "standup_md/task"

module StandupMD
  ##
  # A named section of a standup entry, such as current, previous,
  # impediments, or notes.
  class Section
    ##
    # The semantic section type.
    #
    # @return [Symbol]
    attr_reader :type

    ##
    # Tasks for the section.
    #
    # @return [Array<StandupMD::Task>]
    attr_reader :tasks

    ##
    # Constructs an instance of +StandupMD::Section+.
    #
    # @param [Symbol, String] type
    # @param [Array<String, StandupMD::Task>] tasks
    def initialize(type, tasks = [])
      @type = type.to_sym
      @tasks = tasks.map { |task| build_task(task) }
    end

    ##
    # Adds a task to the section.
    #
    # @param [String, StandupMD::Task] task
    #
    # @return [Array<StandupMD::Task>]
    def <<(task)
      tasks << build_task(task)
    end

    ##
    # Is the section empty?
    #
    # @return [Boolean]
    def empty?
      tasks.empty?
    end

    ##
    # The configured section heading.
    #
    # @return [String]
    def to_s
      StandupMD.config.file.public_send("#{type}_header")
    end

    ##
    # The section rendered as markdown lines.
    #
    # @return [Array<String>]
    def to_markdown
      [
        "#" * StandupMD.config.file.sub_header_depth + " " + to_s,
        *tasks.map(&:to_markdown)
      ]
    end

    private

    def build_task(task)
      return task if task.is_a?(Task)

      Task.new(task)
    end
  end
end
