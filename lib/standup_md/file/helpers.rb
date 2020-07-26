# frozen_string_literal: true

module StandupMD
  class File
    ##
    # Module responsible for reading and writing standup files.
    module Helpers # :nodoc:
      private

      def header?(line) # :nodoc:
        line.match(header_regex)
      end

      def sub_header?(line) # :nodoc:
        line.match(sub_header_regex)
      end

      def header_regex # :nodoc:
        /^#{'#' * StandupMD.config.file.header_depth}\s+/
      end

      def sub_header_regex # :nodoc:
        /^#{'#' * StandupMD.config.file.sub_header_depth}\s+/
      end

      def bullet_character_regex # :nodoc:
        /\s*#{StandupMD.config.file.bullet_character}\s*/
      end

      def determine_section_type(line) # :nodoc:
        line = line.sub(/^\#{#{StandupMD.config.file.sub_header_depth}}\s*/, '')
        [
          StandupMD.config.file.current_header,
          StandupMD.config.file.previous_header,
          StandupMD.config.file.impediments_header,
          StandupMD.config.file.notes_header
        ].each { |header| return header if line.include?(header) }
        raise "Unrecognized header [#{line}]"
      end

      def new_entry(record) # :nodoc:
        Entry.new(
          Date.strptime(record['header'], StandupMD.config.file.header_date_format),
          record[StandupMD.config.file.current_header],
          record[StandupMD.config.file.previous_header],
          record[StandupMD.config.file.impediments_header],
          record[StandupMD.config.file.notes_header]
        )
      end

      def header(date)
        '#' * StandupMD.config.file.header_depth + ' ' + date.strftime(StandupMD.config.file.header_date_format)
      end

      def sub_header(subhead)
        '#' * StandupMD.config.file.sub_header_depth + ' ' + subhead
      end
    end
  end
end
