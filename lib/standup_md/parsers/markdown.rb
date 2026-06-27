# frozen_string_literal: true

require "date"
require "standup_md/entry"
require "standup_md/entry_list"
require "standup_md/section"
require "standup_md/task"

module StandupMD
  ##
  # Namespace for standup file parsers and renderers.
  module Parsers
    ##
    # Parser and renderer for the markdown standup format.
    class Markdown
      ##
      # Raised when markdown cannot be parsed into standup entries.
      class Error < StandardError; end

      ##
      # Access to file configuration.
      #
      # @return [StandupMD::Config::File]
      attr_reader :config

      ##
      # Constructs an instance of +StandupMD::Parsers::Markdown+.
      #
      # @param [StandupMD::Config::File] config
      def initialize(config = StandupMD.config.file)
        @config = config
      end

      ##
      # Parses entries from markdown text.
      #
      # @param [String] text
      #
      # @return [StandupMD::EntryList]
      def parse(text)
        entry_list = EntryList.new
        record = nil
        section = nil

        text.to_s.each_line do |line|
          line.chomp!
          next if line.strip.empty?

          if header?(line)
            entry_list << entry(record) if record
            record = {title: title(line), sections: {}}
            section = section(:notes)
            record[:sections][:notes] = section
          elsif sub_header?(line)
            section = section(section_type(line))
            record[:sections][section.type] = section
          else
            section << task(line)
          end
        end

        entry_list << entry(record) if record
        entry_list.sort
      rescue => e
        raise Error, "Markdown malformation: #{e.message}"
      end

      ##
      # Renders entries as markdown text.
      #
      # @param [StandupMD::EntryList] entries
      # @param [Date] start_date
      # @param [Date] end_date
      #
      # @return [String]
      def render(entries, start_date:, end_date:)
        entries.filter(start_date, end_date).sort_reverse.map do |entry|
          render_entry(entry)
        end.join
      end

      ##
      # Renders a single entry as markdown text.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [String]
      def render_entry(entry)
        lines = [entry_header(entry)]
        config.sub_header_order.each do |type|
          section = Section.new(type, entry.public_send("#{type}_tasks"))
          next if section.empty?

          lines << section_header(type)
          section.tasks.each { |task| lines << task_line(task) }
        end
        lines << ""
        lines.join("\n") + "\n"
      end

      private

      def header?(line)
        line.match?(header_regex)
      end

      def sub_header?(line)
        line.match?(sub_header_regex)
      end

      def header_regex
        /^#{"#" * config.header_depth}\s+/
      end

      def sub_header_regex
        /^#{"#" * config.sub_header_depth}\s+/
      end

      def title(line)
        line.sub(/^\#{#{config.header_depth}}\s*/, "")
      end

      def section(type)
        Section.new(type)
      end

      def entry_header(entry)
        "#{"#" * config.header_depth} #{entry.date.strftime(config.header_date_format)}"
      end

      def section_header(type)
        "#{"#" * config.sub_header_depth} #{config.public_send("#{type}_header")}"
      end

      def section_type(line)
        sub_header = line.sub(/^\#{#{config.sub_header_depth}}\s*/, "")
        Entry::SECTION_TYPES.each do |type|
          header = config.public_send("#{type}_header")
          return type if sub_header == header
        end
        raise "Unrecognized header [#{sub_header}]"
      end

      def task(line)
        match = line.match(task_regex)
        return Task.new(line) unless match

        Task.new(
          match[:text],
          indent_level: match[:indent].size / config.indent_width
        )
      end

      def task_regex
        /\A(?<indent>\s*)#{Regexp.escape(config.bullet_character)}\s*(?<text>.*)\z/
      end

      def task_line(task)
        indent = " " * config.indent_width * task.indent_level
        "#{indent}#{config.bullet_character} #{task.text}"
      end

      def entry(record)
        Entry.new(
          Date.strptime(record[:title], config.header_date_format),
          tasks(record, :current),
          tasks(record, :previous),
          tasks(record, :impediments),
          tasks(record, :notes)
        )
      end

      def tasks(record, type)
        record[:sections].fetch(type, Section.new(type)).tasks
      end
    end
  end
end
