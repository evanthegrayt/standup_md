# frozen_string_literal: true

require "standup_md/parsers/markdown"

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
        return puts "No record found for #{config.cli.date}" if entry.nil?

        puts entry_markdown(entry)
      end

      ##
      # Post an entry to the configured chat adapter.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [StandupMD::Post::Result, nil]
      def post(entry)
        return puts "No record found for #{config.cli.date}" if entry.nil?

        adapter = config.cli.post_adapter || config.post.default_adapter
        message = StandupMD::Post::Message.new(
          entry: entry,
          text: entry_markdown(entry),
          channel: config.cli.post_channel,
          adapter: adapter
        )
        result = config.post.build_adapter(adapter).post(message)
        puts "Could not post to #{result.adapter}: #{result.error}" if result.failure?
        result
      end

      ##
      # Render an entry as markdown.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [String]
      def entry_markdown(entry)
        lines = [header(entry)]
        config.file.sub_header_order.each do |header_type|
          tasks = entry.public_send("#{header_type}_tasks")
          next if tasks.empty?

          lines << sub_header(header_type)
          tasks.each do |task|
            lines << parser.task_line(task)
          end
        end
        lines << ""
        lines.join("\n")
      end

      private

      ##
      # Helper for accessing config.
      #
      # @return [StandupMD::Config]
      def config # :nodoc:
        StandupMD.config
      end

      ##
      # Parses options passed at runtime and concatenates them with the options
      # in the user's preferences file. Reveal source to see options.
      #
      # @return [Hash]
      def load_runtime_preferences(options)
        OptionParser.new do |opts|
          opts.banner = "The Standup Doctor"
          opts.version = "[StandupMD] #{::StandupMD::Version}"
          opts.on(
            "--current ARRAY", Array,
            "List of current entry's tasks"
          ) { |v| config.entry.current = v }

          opts.on(
            "--previous ARRAY", Array,
            "List of previous entry's tasks"
          ) { |v| config.entry.previous = v }

          opts.on(
            "--impediments ARRAY", Array,
            "List of impediments for current entry"
          ) { |v| config.entry.impediments = v }

          opts.on(
            "--notes ARRAY", Array,
            "List of notes for current entry"
          ) { |v| config.entry.notes = v }

          opts.on(
            "--sub-header-order ARRAY", Array,
            "The order of the sub-headers when writing the file"
          ) { |v| config.file.sub_header_order = v }

          opts.on(
            "--indent-width INTEGER", Integer,
            "Number of spaces used for each nested task level"
          ) { |v| config.file.indent_width = v }

          opts.on(
            "-f", "--file-name-format STRING",
            "Date-formattable string to use for standup file name"
          ) { |v| config.file.name_format = v }

          opts.on(
            "-E", "--editor EDITOR",
            "Editor to use for opening standup files"
          ) { |v| config.cli.editor = v }

          opts.on(
            "-d", "--directory DIRECTORY",
            "The directories where standup files are located"
          ) { |v| config.file.directory = v }

          opts.on(
            "-w", "--[no-]write",
            "Write current entry if it doesn't exist. Default is true"
          ) { |v| config.cli.write = v }

          opts.on(
            "-a", "--[no-]auto-fill-previous",
            "Auto-generate 'previous' tasks for new entries. Default is true"
          ) { |v| config.cli.auto_fill_previous = v }

          opts.on(
            "-e", "--[no-]edit",
            "Open the file in the editor. Default is true"
          ) { |v| config.cli.edit = v }

          opts.on(
            "-v", "--[no-]verbose",
            "Verbose output. Default is false."
          ) { |v| config.cli.verbose = v }

          opts.on(
            "--zsh-completion",
            "Print zsh completion setup instructions"
          ) { @zsh_completion_requested = true }

          opts.on(
            "-p", "--print [DATE]",
            "Print current entry.",
            "If DATE is passed, will print entry for DATE, if it exists.",
            "DATE must be in the same format as file-name-format"
          ) do |v|
            config.cli.print = true
            config.cli.date =
              v.nil? ? Date.today : Date.strptime(v, config.file.header_date_format)
          end

          opts.on(
            "-P", "--post [PLATFORM]",
            "Post current entry to a chat client. Defaults to Slack.",
            "If PLATFORM is passed, use that post adapter."
          ) do |v|
            config.cli.post = true
            config.cli.post_adapter = v.nil? ? config.post.default_adapter : v.to_sym
          end

          opts.on(
            "--post-channel CHANNEL",
            "Channel, room, or conversation to post to"
          ) { |v| config.cli.post_channel = v }
        end.parse!(options)
        if zsh_completion_requested?
          raise OptionParser::InvalidArgument, options.join(" ") unless options.empty?

          return
        end

        unless options.empty?
          @file_date_argument = true
          config.cli.date = parse_file_date(options.shift)
        end
        raise OptionParser::InvalidArgument, options.join(" ") unless options.empty?
      end

      ##
      # The entry for today.
      #
      # @return [StandupMD::Entry]
      def new_entry(file)
        entry = file.entries.find(config.cli.date)
        return entry if read_only? || entry || config.cli.date != Date.today

        StandupMD::Entry.new(
          config.cli.date,
          config.entry.current,
          previous_entry(file),
          config.entry.impediments,
          config.entry.notes
        ).tap { |e| file.entries << e }
      end

      ##
      # The "previous" tasks.
      #
      # @return [Array]
      def previous_entry(file)
        return config.entry.previous unless config.cli.auto_fill_previous
        return prev_entry_tasks(prev_file.load.entries) if file.new? && prev_file

        prev_entry_tasks(file.entries)
      end

      ##
      # Parses the optional file date argument.
      #
      # @param [String] value
      #
      # @return [Date]
      def parse_file_date(value)
        case value
        when /\A\d{4}-\d{2}-\d{2}\z/
          Date.strptime(value, "%Y-%m-%d")
        when /\A\d{4}-\d{2}\z/
          Date.strptime(value, "%Y-%m")
        else
          raise OptionParser::InvalidArgument, value
        end
      rescue ArgumentError
        raise OptionParser::InvalidArgument, value
      end

      ##
      # The previous entry's current tasks.
      #
      # @param [StandupMD::EntryList] entries
      #
      # @return [Array<StandupMD::Task>]
      def prev_entry_tasks(entries)
        entries.empty? ? [] : entries.last.current_tasks
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
        "#" * config.file.header_depth + " " +
          entry.date.strftime(config.file.header_date_format)
      end

      ##
      # The sub-header.
      #
      # @param [String] header_type
      #
      # @return [String]
      def sub_header(header_type)
        "#" * config.file.sub_header_depth + " " +
          config.file.public_send("#{header_type}_header")
      end

      def parser
        StandupMD::Parsers::Markdown.new(config.file)
      end
    end
  end
end
