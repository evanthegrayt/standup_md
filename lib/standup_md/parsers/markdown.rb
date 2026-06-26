# frozen_string_literal: true

require "date"
require "standup_md/entry"
require "standup_md/entry_list"
require "standup_md/section"
require "standup_md/task"
require "standup_md/title"

module StandupMD
  ##
  # Namespace for standup file parsers and renderers.
  module Parsers
    ##
    # Parser and renderer for the markdown standup format.
    class Markdown
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
      # Reads entries from a markdown standup file.
      #
      # @param [String] file_name
      #
      # @return [StandupMD::EntryList]
      def read(file_name)
        entry_list = EntryList.new
        record = nil
        section = nil

        ::File.foreach(file_name) do |line|
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
        raise "File malformation: #{e}"
      end

      ##
      # Writes entries to a markdown standup file.
      #
      # @param [String] file_name
      # @param [StandupMD::EntryList] entries
      # @param [Date] start_date
      # @param [Date] end_date
      #
      # @return [Boolean]
      def write(file_name, entries, start_date:, end_date:)
        ::File.open(file_name, "w") do |f|
          entries.filter(start_date, end_date).sort_reverse.each do |entry|
            f.puts Title.new(entry.date).to_markdown
            config.sub_header_order.each do |attr|
              section = Section.new(attr, entry.public_send("#{attr}_tasks"))
              next if section.empty?

              f.puts section.to_markdown
            end
            f.puts
          end
        end
        true
      end

      ##
      # Renders a task as a markdown list item.
      #
      # @param [String, StandupMD::Task] task
      #
      # @return [String]
      def task_line(task)
        build_task(task).to_markdown
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

      def section_type(line)
        sub_header = line.sub(/^\#{#{config.sub_header_depth}}\s*/, "")
        Entry::SECTION_TYPES.each do |type|
          header = config.public_send("#{type}_header")
          return type if sub_header.include?(header)
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

      def build_task(task)
        return task if task.is_a?(Task)

        Task.new(task)
      end
    end
  end
end
