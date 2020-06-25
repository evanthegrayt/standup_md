# frozen_string_literal: true

module StandupMD
  class Cli

    ##
    # Module responsible for reading and writing standup files.
    module Helpers

      ##
      # Print an entry to the command line.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [nil]
      def print(entry)
        if entry.nil?
          puts "No record found for #{StandupMD.config.cli.date}"
          return
        end
        puts header(entry)
        StandupMD.config.file.sub_header_order.each do |header_type|
          tasks = entry.public_send(header_type)
          next if !tasks || tasks.empty?
          puts sub_header(header_type)
          tasks.each { |task| puts StandupMD.config.file.bullet_character + ' ' + task }
        end
        puts
      end

      private

      ##
      # Parses options passed at runtime and concatenates them with the options
      # in the user's preferences file. Reveal source to see options.
      #
      # @return [Hash]
      def set_preferences(options)
        OptionParser.new do |opts|
          opts.banner = 'The Standup Doctor'
          opts.version = "[StandupMD] #{::StandupMD::Version.to_s}"
          opts.on(
            '--current ARRAY', Array,
            "List of current entry's tasks"
          ) { |v| StandupMD.config.entry.current = v }

          opts.on(
            '--previous ARRAY', Array,
            "List of precious entry's tasks"
          ) { |v| StandupMD.config.entry.previous = v }

          opts.on(
            '--impediments ARRAY', Array,
            'List of impediments for current entry'
          ) { |v| StandupMD.config.entry.impediments = v }

          opts.on(
            '--notes ARRAY', Array,
            'List of notes for current entry'
          ) { |v| StandupMD.config.entry.notes = v }

          opts.on(
            '--sub-header-order ARRAY', Array,
            'The order of the sub-headers when writing the file'
          ) { |v| StandupMD.config.file.sub_header_order = v }

          opts.on(
            '-f', '--file-name-format STRING',
            'Date-formattable string to use for standup file name'
          ) { |v| StandupMD.config.file.name_format = v }

          opts.on(
            '-E', '--editor EDITOR',
            'Editor to use for opening standup files'
          ) { |v| StandupMD.config.cli.editor = v }

          opts.on(
            '-d', '--directory DIRECTORY',
            'The directories where standup files are located'
          ) { |v| StandupMD.config.file.directory = v }

          opts.on(
            '-w', '--[no-]write',
            "Write current entry if it doesn't exist. Default is true"
          ) { |v| StandupMD.config.cli.write = v }

          opts.on(
            '-a', '--[no-]auto-fill-previous',
            "Auto-generate 'previous' tasks for new entries. Default is true"
          ) { |v| StandupMD.config.cli.auto_fill_previous = v }

          opts.on(
            '-e', '--[no-]edit',
            'Open the file in the editor. Default is true'
          ) { |v| StandupMD.config.cli.edit = v }

          opts.on(
            '-v', '--[no-]verbose',
            'Verbose output. Default is false.'
          ) { |v| StandupMD.config.cli.verbose = v }

          opts.on(
            '-p', '--print [DATE]',
            'Print current entry.',
            'If DATE is passed, will print entry for DATE, if it exists.',
            'DATE must be in the same format as file-name-format',
          ) do |v|
            StandupMD.config.cli.print = true
            StandupMD.config.cli.date =
              v.nil? ? Date.today : Date.strptime(v, StandupMD.config.file.header_date_format)
          end
        end.parse!(options)
      end

      ##
      # The entry for today.
      #
      # @return [StandupMD::Entry]
      def set_entry(file)
        entry = file.entries.find(StandupMD.config.cli.date)
        if entry.nil? && StandupMD.config.cli.date == Date.today
          previous_entry = set_previous_entry(file)
          entry = StandupMD::Entry.new(
            StandupMD.config.cli.date,
            StandupMD.config.entry.current,
            previous_entry,
            StandupMD.config.entry.impediments,
            StandupMD.config.entry.notes
          )
          file.entries << entry
        end
        entry
      end

      ##
      # The "previous" entries.
      #
      # @return [Array]
      def set_previous_entry(file)
        unless StandupMD.config.cli.auto_fill_previous
          return Standup.config.entry.previous_entry
        end
        return prev_entry(prev_file.load.entries) if file.new? && prev_file
        prev_entry(file.entries)
      end

      ##
      # The previous entry.
      #
      # @param [StandupMD::EntryList] entries
      #
      # @return [StandupMD::Entry]
      def prev_entry(entries)
        return [] if entries.empty?
        entries.last.current
      end

      ##
      # The previous month's file.
      #
      # @return [StandupMD::File]
      def prev_file
        StandupMD::File.find_by_date(Date.today.prev_month)
      end

      ##
      # The header.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [String]
      def header(entry)
        '#' * StandupMD.config.file.header_depth + ' ' +
          entry.date.strftime(StandupMD.config.file.header_date_format)
      end

      ##
      # The sub-header.
      #
      # @param [String] header_type
      #
      # @return [String]
      def sub_header(header_type)
        '#' * StandupMD.config.file.sub_header_depth + ' ' +
          StandupMD.config.file.public_send("#{header_type}_header").capitalize
      end
    end
  end
end
