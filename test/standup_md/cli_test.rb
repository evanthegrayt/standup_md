# frozen_string_literal: true

require_relative "../test_helper"

##
# The test suite for +Cli+.
class TestCli < TestHelper
  def setup
    super
    create_standup_file(test_file_name)
    StandupMD.config.cli.reset
    StandupMD.config.file.reset
    StandupMD.config.entry.reset
    StandupMD.config.entry_list.reset
    StandupMD.config.cli.preference_file = test_config_file_name
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
    StandupMD.config.entry_list.reset
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
    assert_equal(Date.new(previous_month.year, previous_month.month, 1), StandupMD.config.cli.date)
  end

  def test_file_date_argument_accepts_full_date
    previous_month = Date.today.prev_month
    create_standup_file(@previous_month_test_file, "previous_month_entry")

    c = cli(@options + [previous_month.strftime("%Y-%m-%d")])

    assert_equal(previous_month.strftime("%Y_%m.md"), File.basename(c.file.name))
    assert_equal(previous_month, StandupMD.config.cli.date)
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

  def test_print_is_read_only
    c = cli(["--print", "--directory", workdir.to_s])

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

  def test_preferences
    cli(@options)
    refute(StandupMD.config.cli.write)
    refute(StandupMD.config.cli.edit)
    assert_equal(workdir, StandupMD.config.file.directory)
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
    cli(@options)
    refute(StandupMD.config.cli.verbose)

    cli(["--directory", workdir.to_s, "-v"] + @options)
    assert(StandupMD.config.cli.verbose)
  end

  def test_write
    cli(@options)
    refute(StandupMD.config.cli.write)

    cli(["--directory", workdir.to_s, "--write"] + @options)
    assert(StandupMD.config.cli.write)
  end

  def test_auto_fill_previous
    assert(StandupMD.config.cli.auto_fill_previous)
    cli(@options)

    cli(["--no-auto-fill-previous"] + @options)
    refute(StandupMD.config.cli.auto_fill_previous)
  end

  def test_write_file
    c = cli(@options)
    assert_nothing_raised { c.write_file }
  end

  def test_current
    cli(["--directory", workdir.to_s])
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)

    cli(["--current", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], StandupMD.config.entry.current)
  end

  def test_previous
    cli(["--directory", workdir.to_s])
    assert_equal([], StandupMD.config.entry.previous)

    cli(["--previous", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], StandupMD.config.entry.previous)
  end

  def test_impediments
    cli(["--directory", workdir.to_s])
    assert_equal(["None"], StandupMD.config.entry.impediments)

    cli(["--impediments", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], StandupMD.config.entry.impediments)
  end

  def test_notes
    cli(["--directory", workdir.to_s])
    assert_equal([], StandupMD.config.entry.notes)

    cli(["--notes", "test", "--directory", workdir.to_s])
    assert_equal(%w[test], StandupMD.config.entry.notes)
  end

  def test_sub_header_order
    cli(["--directory", workdir.to_s])
    assert_equal(%w[previous current impediments notes], StandupMD.config.file.sub_header_order)

    cli(
      ["--sub-header-order", "current,previous,notes,impediments", "--directory", workdir.to_s],
      load_config: false
    )
    assert_equal(
      %w[current previous notes impediments],
      StandupMD.config.file.sub_header_order
    )
  end

  def test_indent_width
    cli(["--directory", workdir.to_s])
    assert_equal(2, StandupMD.config.file.indent_width)

    cli(["--indent-width", "4", "--directory", workdir.to_s])
    assert_equal(4, StandupMD.config.file.indent_width)
  end

  def test_file_name_format
    cli(["--directory", workdir.to_s], load_config: false)
    assert_equal("%Y_%m.md", StandupMD.config.file.name_format)

    cli(["--file-name-format", "%y_%m.md", "--directory", workdir.to_s])
    assert_equal("%y_%m.md", StandupMD.config.file.name_format)
  end

  def test_editor
    ENV["VISUAL"] = "vim"
    cli(["--directory", workdir.to_s])
    assert_equal("vim", StandupMD.config.cli.editor)

    cli(["--editor", "mate", "--directory", workdir.to_s])
    assert_equal("mate", StandupMD.config.cli.editor)
  end

  def test_print
    enable_stdout_redirection

    cli(["--directory", workdir.to_s])
    refute(StandupMD.config.cli.print)

    cli(["--print", "--directory", workdir.to_s])
    assert(StandupMD.config.cli.print)
    assert_equal(Date.today, StandupMD.config.cli.date)

    cli(
      [
        "--print",
        "--directory", workdir.to_s,
        "--print", Date.today.prev_day.strftime(StandupMD.config.file.header_date_format).to_s
      ]
    )
    assert(StandupMD.config.cli.print)
    assert_equal(Date.today.prev_day, StandupMD.config.cli.date)
  ensure
    disable_stdout_redireaction
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
