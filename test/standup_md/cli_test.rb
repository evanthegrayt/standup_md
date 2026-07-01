# frozen_string_literal: true

require_relative "../test_helper"

##
# The test suite for +Cli+.
class TestCli < TestHelper
  class RecordingPostAdapter
    class << self
      attr_accessor :messages
    end

    attr_reader :options

    def initialize(options = {})
      @options = options
    end

    def post(message)
      self.class.messages << [message, options]
      StandupMD::Post::Result.success(
        adapter: message.adapter,
        channel: message.channel || options[:channel]
      )
    end
  end

  def setup
    super
    RecordingPostAdapter.messages = []
    StandupMD.config.cli.reset
    StandupMD.config.file.reset
    StandupMD.config.entry.reset
    StandupMD.config.post.reset
    StandupMD.config.cli.preference_file = test_config_file_name
    StandupMD.config.file.directory = workdir
    create_standup_file(test_file_name)
    StandupMD.instance_variable_set(:@config_file_loaded, false)
    @previous_month_test_file =
      File.join(workdir, Date.today.prev_month.strftime("%Y_%m.md"))
    @options = ["--no-edit", "--no-write", "--directory", workdir.to_s]
  end

  def teardown
    super
    StandupMD.config.cli.reset
    StandupMD.config.file.reset
    StandupMD.config.entry.reset
    StandupMD.config.post.reset
  end

  def test_preference_file
    assert_equal(
      test_config_file_name,
      StandupMD.config.cli.preference_file
    )
  end

  def test_load_preferences
    c = cli(@options, load_config: false)
    refute(c.preference_file_loaded?)
    create_config_file(test_config_file_name)
    c.load_preferences
    assert(c.preference_file_loaded?)
  end

  def test_self_execute
    enable_stdout_redirection
    assert_nothing_raised { StandupMD::Cli.execute(@options) }
    assert_nothing_raised { StandupMD::Cli.execute(@options + %w[--print]) }
  ensure
    disable_stdout_redireaction
  end

  def test_self_execute_with_file_date_argument
    previous_month = Date.today.prev_month
    create_standup_file(@previous_month_test_file, "previous_month_entry")

    assert_nothing_raised do
      StandupMD::Cli.execute(
        [
          "--no-edit",
          "--directory", workdir.to_s,
          previous_month.strftime("%Y-%m")
        ]
      )
    end
    assert(File.file?(@previous_month_test_file))
  end

  def test_current_entry
    c = cli(@options)
    assert_instance_of(StandupMD::Entry, c.entry)

    StandupMD.config.cli.date = Date.today.prev_month
    StandupMD.config.file.create = true

    c = cli(@options)
    assert_nil(c.entry)
  end

  def test_file_date_argument
    previous_month = Date.today.prev_month
    create_standup_file(@previous_month_test_file, "previous_month_entry")

    c = cli(@options + [previous_month.strftime("%Y-%m")])

    assert_equal(previous_month.strftime("%Y_%m.md"), File.basename(c.file.name))
    assert_equal(Date.new(previous_month.year, previous_month.month, 1), c.config.cli.date)
    assert_equal(Date.today, StandupMD.config.cli.date)
  end

  def test_file_date_argument_accepts_full_date
    previous_month = Date.today.prev_month
    create_standup_file(@previous_month_test_file, "previous_month_entry")

    c = cli(@options + [previous_month.strftime("%Y-%m-%d")])

    assert_equal(previous_month.strftime("%Y_%m.md"), File.basename(c.file.name))
    assert_equal(previous_month, c.config.cli.date)
    assert_equal(Date.today, StandupMD.config.cli.date)
  end

  def test_file_date_argument_is_read_only
    previous_month = Date.today.prev_month
    create_standup_file(@previous_month_test_file, "previous_month_entry")

    c = cli(["--no-edit", "--directory", workdir.to_s, previous_month.strftime("%Y-%m-%d")])

    assert(c.file_date_argument?)
    refute(c.write?)
  end

  def test_file_date_argument_does_not_create_missing_file
    previous_month = Date.today.prev_month

    assert_raise do
      cli(@options + [previous_month.strftime("%Y-%m")])
    end
    refute(File.file?(@previous_month_test_file))
    assert(StandupMD.config.file.create)
  end

  def test_auto_fill_previous_does_not_create_missing_previous_file
    FileUtils.rm(test_file_name)

    c = cli(["--no-edit", "--directory", workdir.to_s])

    assert(c.file.new?)
    assert_equal([], c.entry.previous)
    refute(File.file?(@previous_month_test_file))
    assert(StandupMD.config.file.create)
  end

  def test_print_is_read_only
    c = cli(["--print", "--directory", workdir.to_s])

    refute(c.file_date_argument?)
    refute(c.write?)
  end

  def test_post_is_read_only
    c = cli(["--post", "--directory", workdir.to_s])

    assert(c.post?)
    refute(c.file_date_argument?)
    refute(c.write?)
  end

  def test_print_does_not_create_missing_file
    previous_month = Date.today.prev_month

    c = cli(
      [
        "--print", previous_month.strftime(StandupMD.config.file.header_date_format),
        "--directory", workdir.to_s
      ]
    )

    assert_nil(c.file)
    assert_nil(c.entry)
    refute(File.file?(@previous_month_test_file))
    assert(StandupMD.config.file.create)
  end

  def test_post_does_not_create_missing_file
    previous_month = Date.today.prev_month

    c = cli(
      [
        "--post", "slack",
        previous_month.strftime(StandupMD.config.file.header_date_format),
        "--directory", workdir.to_s
      ]
    )

    assert_nil(c.file)
    assert_nil(c.entry)
    refute(File.file?(@previous_month_test_file))
    assert(StandupMD.config.file.create)
  end

  def test_file_date_argument_rejects_invalid_date
    assert_raise(OptionParser::InvalidArgument) do
      cli(@options + ["2026-6"])
    end

    assert_raise(OptionParser::InvalidArgument) do
      cli(@options + ["2026-02-31"])
    end

    assert_raise(OptionParser::InvalidArgument) do
      cli(@options + %w[2026-06 2026-07])
    end
  end

  def test_options
    c = cli(@options)
    assert_equal(@options, c.options)
  end

  def test_cli_options_do_not_mutate_global_config
    c = cli(
      [
        "--current", "Runtime current",
        "--no-edit",
        "--no-write",
        "--print",
        "--directory", workdir.to_s
      ]
    )

    assert_equal(["Runtime current"], c.config.entry.current)
    assert(c.config.cli.print)
    refute(c.config.cli.edit)
    refute(c.config.cli.write)

    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)
    refute(StandupMD.config.cli.print)
    assert(StandupMD.config.cli.edit)
    assert(StandupMD.config.cli.write)
  end

  def test_sequential_cli_instances_do_not_leak_runtime_options
    first = cli(["--current", "One", "--no-edit", "--directory", workdir.to_s])
    second = cli(["--previous", "Two", "--print", "--directory", workdir.to_s])

    assert_equal(["One"], first.config.entry.current)
    refute(first.config.cli.print)
    assert_equal([], first.config.entry.previous)

    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], second.config.entry.current)
    assert(second.config.cli.print)
    assert_equal(["Two"], second.config.entry.previous)
  end

  def test_preferences
    c = cli(@options)
    refute(c.config.cli.write)
    refute(c.config.cli.edit)
    assert_equal(workdir, c.config.file.directory)
    assert(StandupMD.config.cli.write)
    assert(StandupMD.config.cli.edit)
  end

  def test_initialize
    assert_nothing_raised { StandupMD::Cli.new(@options) }
    assert_nothing_raised { StandupMD::Cli.new(@options) }
  end

  def test_zsh_completion
    c = cli(["--zsh-completion"])

    assert(c.zsh_completion_requested?)
    assert_nil(c.file)
    assert_nil(c.entry)
    assert_match(
      %r{completion/zsh/_standup},
      StandupMD::Cli.zsh_completion_instructions
    )
  end

  def test_zsh_completion_omits_file_format_options
    completion = File.read(StandupMD::Cli::ZSH_COMPLETION_FILE)
    unsafe_options = %w[
      --sub-header-order
      --indent-width
      --file-name-format
      --header-depth
      --sub-header-depth
      --bullet-character
      --header-date-format
      --current-header
      --previous-header
      --impediments-header
      --notes-header
    ]

    unsafe_options.each do |option|
      refute_includes(completion, option)
    end
  end

  def test_self_execute_with_zsh_completion
    enable_stdout_redirection

    assert_nothing_raised { StandupMD::Cli.execute(["--zsh-completion"]) }
    $stdout.flush

    output = File.read(test_output_file)
    assert_match(/Zsh completion file:/, output)
    assert_match(%r{completion/zsh/_standup}, output)
    assert_match(/fpath=/, output)
  ensure
    disable_stdout_redireaction
  end

  def test_verbose
    c = cli(@options)
    refute(c.config.cli.verbose)
    refute(StandupMD.config.cli.verbose)

    c = cli(["--directory", workdir.to_s, "-v"] + @options)
    assert(c.config.cli.verbose)
    refute(StandupMD.config.cli.verbose)
  end

  def test_write
    c = cli(@options)
    refute(c.config.cli.write)
    assert(StandupMD.config.cli.write)

    c = cli(["--directory", workdir.to_s, "--write"] + @options)
    assert(c.config.cli.write)
    assert(StandupMD.config.cli.write)
  end

  def test_auto_fill_previous
    assert(StandupMD.config.cli.auto_fill_previous)
    c = cli(@options)
    assert(c.config.cli.auto_fill_previous)

    c = cli(["--no-auto-fill-previous"] + @options)
    refute(c.config.cli.auto_fill_previous)
    assert(StandupMD.config.cli.auto_fill_previous)
  end

  def test_no_auto_fill_previous_uses_configured_previous_tasks
    ::File.open(test_file_name, "w") do |f|
      f.puts "# #{Date.today.prev_day.strftime(StandupMD.config.file.header_date_format)}"
      f.puts "## Previous"
      f.puts "- Yesterday"
      f.puts "## Current"
      f.puts "- Yesterday's current task"
      f.puts "## Impediments"
      f.puts "- None"
    end

    c = cli(
      [
        "--no-auto-fill-previous",
        "--previous", "Configured previous task",
        "--no-edit",
        "--directory", workdir.to_s
      ]
    )

    assert_equal(["Configured previous task"], c.entry.previous)
  end

  def test_auto_fill_previous_preserves_indented_markdown_tasks
    StandupMD.config.file.current_header = "Today"
    ::File.open(test_file_name, "w") do |f|
      f.puts "# #{Date.today.prev_day.strftime(StandupMD.config.file.header_date_format)}"
      f.puts "## Previous"
      f.puts "- Upgrade React 16.8 to React 17"
      f.puts "  - Test, test, test"
      f.puts "## Today"
      f.puts "- Standing 10:30 meeting"
      f.puts "- Get React 17 upgrade across the finish line"
      f.puts "  - Meet with Chris to look over things"
      f.puts "  - Continue to test, test, test"
      f.puts "- Spike: Plan React 17 cleanup and 18 upgrade"
      f.puts "  - A skeleton plan exists but it needs to be fleshed out with all new details"
      f.puts "## Impediments"
      f.puts "- None"
    end

    c = cli(["--no-edit", "--directory", workdir.to_s])
    c.write_file

    assert_equal(
      [
        "# #{Date.today.strftime(StandupMD.config.file.header_date_format)}",
        "## Previous",
        "- Standing 10:30 meeting",
        "- Get React 17 upgrade across the finish line",
        "  - Meet with Chris to look over things",
        "  - Continue to test, test, test",
        "- Spike: Plan React 17 cleanup and 18 upgrade",
        "  - A skeleton plan exists but it needs to be fleshed out with all new details",
        "## Today",
        "- <!-- ADD TODAY'S WORK HERE -->",
        "## Impediments",
        "- None",
        ""
      ],
      ::File.read(test_file_name).lines.map(&:chomp).first(13)
    )
  end

  def test_write_file
    c = cli(@options)
    assert_nothing_raised { c.write_file }
  end

  def test_existing_current_entry_does_not_append_configured_current
    StandupMD.config.entry.current = ["Configured current"]

    c = cli(["--no-edit", "--directory", workdir.to_s])
    c.write_file

    entry = StandupMD::File.load(
      File.basename(test_file_name),
      config: c.config.file
    ).entries.find(Date.today)

    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], entry.current)
  end

  def test_current_option_appends_to_existing_current_entry
    StandupMD::Cli.execute(
      [
        "--current", "New task",
        "--no-edit",
        "--directory", workdir.to_s
      ]
    )

    entry = StandupMD::File.load(
      File.basename(test_file_name),
      config: StandupMD.config.file
    )
      .entries.find(Date.today)

    assert_equal(["<!-- ADD TODAY'S WORK HERE -->", "New task"], entry.current)
  end

  def test_current
    c = cli(["--directory", workdir.to_s])
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], c.config.entry.current)
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)

    c = cli(["--current", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], c.config.entry.current)
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)
  end

  def test_previous
    c = cli(["--directory", workdir.to_s])
    assert_equal([], c.config.entry.previous)
    assert_equal([], StandupMD.config.entry.previous)

    c = cli(["--previous", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], c.config.entry.previous)
    assert_equal([], StandupMD.config.entry.previous)
  end

  def test_impediments
    c = cli(["--directory", workdir.to_s])
    assert_equal(["None"], c.config.entry.impediments)
    assert_equal(["None"], StandupMD.config.entry.impediments)

    c = cli(["--impediments", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], c.config.entry.impediments)
    assert_equal(["None"], StandupMD.config.entry.impediments)
  end

  def test_notes
    c = cli(["--directory", workdir.to_s])
    assert_equal([], c.config.entry.notes)
    assert_equal([], StandupMD.config.entry.notes)

    c = cli(["--notes", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], c.config.entry.notes)
    assert_equal([], StandupMD.config.entry.notes)
  end

  def test_file_format_options_are_config_only
    assert_raise(OptionParser::InvalidOption) do
      cli(["--sub-header-order", "current,previous", "--directory", workdir.to_s])
    end

    assert_raise(OptionParser::InvalidOption) do
      cli(["--indent-width", "4", "--directory", workdir.to_s])
    end

    assert_raise(OptionParser::InvalidOption) do
      cli(["--file-name-format", "%y_%m.md", "--directory", workdir.to_s])
    end

    assert_raise(OptionParser::InvalidOption) do
      cli(["-f", "%y_%m.md", "--directory", workdir.to_s])
    end
  end

  def test_editor
    ENV["VISUAL"] = "vim"
    c = cli(["--directory", workdir.to_s])
    assert_equal("vim", c.config.cli.editor)
    assert_equal("vim", StandupMD.config.cli.editor)

    c = cli(["--editor", "mate", "--directory", workdir.to_s])
    assert_equal("mate", c.config.cli.editor)
    assert_equal("vim", StandupMD.config.cli.editor)
  end

  def test_print
    enable_stdout_redirection

    c = cli(["--directory", workdir.to_s])
    refute(c.config.cli.print)
    refute(StandupMD.config.cli.print)

    c = cli(["--print", "--directory", workdir.to_s])
    assert(c.config.cli.print)
    assert_equal(Date.today, c.config.cli.date)
    refute(StandupMD.config.cli.print)

    c = cli(
      [
        "--print",
        "--directory", workdir.to_s,
        "--print", Date.today.prev_day.strftime(StandupMD.config.file.header_date_format).to_s
      ]
    )
    assert(c.config.cli.print)
    assert_equal(Date.today.prev_day, c.config.cli.date)
    refute(StandupMD.config.cli.print)
  ensure
    disable_stdout_redireaction
  end

  def test_post
    c = cli(["--post", "--directory", workdir.to_s])

    assert(c.config.cli.post)
    assert_equal(:slack, c.config.cli.post_adapter)
    refute(StandupMD.config.cli.post)
    assert_nil(StandupMD.config.cli.post_adapter)

    c = cli(["--post", "slack", "--directory", workdir.to_s])

    assert(c.config.cli.post)
    assert_equal(:slack, c.config.cli.post_adapter)
    refute(StandupMD.config.cli.post)
    assert_nil(StandupMD.config.cli.post_adapter)
  end

  def test_post_channel
    c = cli(["--post", "slack", "--post-channel", "C123", "--directory", workdir.to_s])

    assert_equal("C123", c.config.cli.post_channel)
    assert_nil(StandupMD.config.cli.post_channel)
  end

  def test_post_invokes_custom_adapter
    StandupMD.config.post.register_adapter(:test, RecordingPostAdapter)
    StandupMD.config.post.configure_adapter(:test, channel: "configured")

    StandupMD::Cli.execute(
      [
        "--post", "test",
        "--post-channel", "runtime",
        "--directory", workdir.to_s
      ]
    )

    assert_equal(1, RecordingPostAdapter.messages.size)
    message, options = RecordingPostAdapter.messages.first
    assert_equal(:test, message.adapter)
    assert_equal("runtime", message.channel)
    assert_equal({channel: "configured"}, options)
    assert_match(/# #{Date.today.strftime(StandupMD.config.file.header_date_format)}/, message.text)
    assert_match(/\n- <!-- ADD TODAY'S WORK HERE -->\n/, message.text)
  end

  def test_post_uses_configured_channel_when_runtime_channel_is_omitted
    StandupMD.config.post.register_adapter(:test, RecordingPostAdapter)
    StandupMD.config.post.configure_adapter(:test, channel: "configured")

    StandupMD::Cli.execute(
      [
        "--post", "test",
        "--directory", workdir.to_s
      ]
    )

    message, options = RecordingPostAdapter.messages.first
    assert_nil(message.channel)
    assert_equal({channel: "configured"}, options)
  end

  def test_class_print
    enable_stdout_redirection
    entry = StandupMD::Entry.new(
      Date.today,
      %w[Current task],
      %w[Previous task],
      %w[Impediment]
    )
    assert_nothing_raised { cli(@options).print(entry) }
    assert_nothing_raised { cli(@options).print(nil) }
  ensure
    disable_stdout_redireaction
  end

  def test_class_print_preserves_indented_markdown_tasks
    enable_stdout_redirection
    entry = StandupMD::Entry.new(
      Date.today,
      [
        "Working issue number 1",
        StandupMD::Task.new("Did this supporting subtask", indent_level: 1)
      ],
      %w[Previous task],
      %w[Impediment]
    )

    cli(@options).print(entry)
    $stdout.flush

    assert_match(
      /\n- Working issue number 1\n  - Did this supporting subtask\n/,
      ::File.read(test_output_file)
    )
  ensure
    disable_stdout_redireaction
  end
end
