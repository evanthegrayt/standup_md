# frozen_string_literal: true

require "standup_md/parsers/markdown"
require "standup_md/post"

module StandupMD
  class Cli
    ##
    # Helpers for CLI commands and option handling.
    module Helpers
      ##
      # Print an entry to the command line.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [nil]
      def print(entry)
        return puts "No record found for #{config.cli.date}" if entry.nil?

        $stdout.print markdown.render_entry(entry)
      end

      ##
      # Post an entry to the configured chat adapter.
      #
      # @param [StandupMD::Entry] entry
      #
      # @return [StandupMD::Post::Result, nil]
      def post(entry)
        return puts "No record found for #{config.cli.date}" if entry.nil?

        result = StandupMD::Post.post(
          entry,
          adapter: config.cli.post_adapter,
          channel: config.cli.post_channel,
          config: config
        )
        puts "Could not post to #{result.adapter}: #{result.error}" if result.failure?
        result
      end

      private

      ##
      # Helper for accessing config.
      #
      # @return [StandupMD::Config]
      def config # :nodoc:
        @config
      end

      ##
      # Parses options passed at runtime into this CLI invocation's config
      # snapshot. Reveal source to see options.
      #
      # @return [Hash]
      def load_runtime_preferences(options)
        OptionParser.new do |opts|
          opts.banner = "The Standup Doctor"
          opts.version = "[StandupMD] #{::StandupMD::Version}"
          opts.on(
            "--current ARRAY", Array,
            "List of current entry's tasks"
          ) do |v|
            @current_option_passed = true
            config.entry.current = v
          end

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
            "-E", "--editor EDITOR",
            "Editor to use for opening standup files"
          ) { |v| config.cli.editor = v }

          opts.on(
            "-d", "--directory DIRECTORY",
            "The directory where standup files are located"
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
            "-i", "--[no-]carry-forward-impediments",
            "Carry impediments forward for new entries. Default is false"
          ) { |v| config.cli.carry_forward_impediments = v }

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
            "DATE must be in the same format as the entry header date."
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
        return entry if read_only? || config.cli.date != Date.today
        if entry
          append_current_entry(entry) if current_option_passed?
          return entry
        end

        StandupMD::Entry.new(
          config.cli.date,
          config.entry.current,
          previous_entry(file),
          impediments_entry(file),
          config.entry.notes
        ).tap { |e| file.entries << e }
      end

      ##
      # The "previous" tasks.
      #
      # @return [Array]
      def previous_entry(file)
        return config.entry.previous unless config.cli.auto_fill_previous

        carry_forward_tasks(file, fallback: []) { |entry| entry.current_tasks }
      end

      ##
      # The "impediments" tasks.
      #
      # @return [Array]
      def impediments_entry(file)
        return config.entry.impediments unless config.cli.carry_forward_impediments

        carry_forward_tasks(file, fallback: config.entry.impediments) do |entry|
          entry.impediments_tasks
        end
      end

      def append_current_entry(entry)
        current = entry.section(:current)
        config.entry.current.each { |task| current << task }
      end

      def current_option_passed?
        @current_option_passed
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

      def carry_forward_tasks(file, fallback:)
        entry = carry_forward_entry(file)
        entry.nil? ? fallback : yield(entry)
      end

      def carry_forward_entry(file)
        carry_forward_entries(file).last
      end

      def carry_forward_entries(file)
        return file.entries unless file.new?

        find_previous_month_file&.load&.entries || file.entries
      end

      ##
      # The previous month's file.
      #
      # @param [StandupMD::Config::File] config
      #
      # @return [StandupMD::File]
      def previous_month_file(config: self.config.file)
        StandupMD::File.find_by_date(Date.today.prev_month, config: config)
      end

      def previous_month_file?
        ::File.file?(previous_month_file_path)
      end

      def find_previous_month_file
        return nil unless previous_month_file?

        without_file_creation do |file_config|
          previous_month_file(config: file_config)
        end
      end

      def previous_month_file_path
        ::File.join(
          config.file.directory,
          Date.today.prev_month.strftime(config.file.name_format)
        )
      end

      ##
      # Markdown renderer used for CLI output.
      #
      # @return [StandupMD::Parsers::Markdown]
      def markdown
        StandupMD::Parsers::Markdown.new(config.file)
      end
    end
  end
end
