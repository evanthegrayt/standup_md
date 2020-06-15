# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/standup_md'

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
    StandupMD.instance_variable_set('@config_file_loaded', false)
    @previous_month_test_file =
      File.join(workdir, Date.today.prev_month.strftime('%Y_%m.md'))
    @options = ['--no-edit', '--no-write', '--directory', "#{workdir}"]
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
    c = cli(@options, false)
    refute(c.preference_file_loaded?)
    create_config_file(test_config_file_name)
    c.load_preferences
    assert(c.preference_file_loaded?)
  end

  def test_self_execute
    enable_stdout_redirection
    assert_nothing_raised { StandupMD::Cli.execute(@options) }
    assert_nothing_raised { StandupMD::Cli.execute(@options + ['--print']) }
  ensure
    disable_stdout_redireaction
  end

  def test_current_entry
    c = cli(@options)
    assert_instance_of(StandupMD::Entry, c.entry)

    StandupMD.config.cli.date = Date.today.prev_month
    StandupMD.config.file.create = true

    c = cli(@options)
    assert_nil(c.entry)
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

  def test_verbose
    cli(@options)
    refute(StandupMD.config.cli.verbose)

    cli(['--directory', "#{workdir}", '-v'] + @options)
    assert(StandupMD.config.cli.verbose)
  end

  def test_write
    cli(@options)
    refute(StandupMD.config.cli.write)

    cli(['--directory', "#{workdir}", '--write'] + @options)
    assert(StandupMD.config.cli.write)
  end

  def test_auto_fill_previous
    assert(StandupMD.config.cli.auto_fill_previous)
    cli(@options)

    cli(['--no-auto-fill-previous'] + @options)
    refute(StandupMD.config.cli.auto_fill_previous)
  end

  def test_write_file
    c = cli(@options)
    assert_nothing_raised { c.write_file }
  end

  def test_current
    cli(['--directory', "#{workdir}"])
    assert_equal(["<!-- ADD TODAY'S WORK HERE -->"], StandupMD.config.entry.current)

    cli(['--current', 'test', '--directory', "#{workdir}"])
    assert_equal(["test"], StandupMD.config.entry.current)
  end

  def test_previous
    cli(['--directory', "#{workdir}"])
    assert_equal([], StandupMD.config.entry.previous)

    cli(['--previous', 'test', '--directory', "#{workdir}"])
    assert_equal(["test"], StandupMD.config.entry.previous)
  end

  def test_impediments
    cli(['--directory', "#{workdir}"])
    assert_equal(['None'], StandupMD.config.entry.impediments)

    cli(['--impediments', 'test', '--directory', "#{workdir}"])
    assert_equal(["test"], StandupMD.config.entry.impediments)
  end

  def test_notes
    cli(['--directory', "#{workdir}"])
    assert_equal([], StandupMD.config.entry.notes)

    cli(['--notes', 'test', '--directory', "#{workdir}"])
    assert_equal(["test"], StandupMD.config.entry.notes)
  end

  def test_sub_header_order
    cli(['--directory', "#{workdir}"])
    assert_equal(
      %w[previous current impediments notes],
      StandupMD.config.file.sub_header_order
    )

    cli(
      ['--sub-header-order', 'current,previous,notes,impediments', '--directory', "#{workdir}"],
      false
    )
    assert_equal(
      %w[current previous notes impediments],
      StandupMD.config.file.sub_header_order
    )
  end

  def test_file_name_format
    cli(['--directory', "#{workdir}"], false)
    assert_equal('%Y_%m.md', StandupMD.config.file.name_format)

    cli(['--file-name-format', '%y_%m.md', '--directory', "#{workdir}"])
    assert_equal('%y_%m.md', StandupMD.config.file.name_format)
  end

  def test_editor
    ENV['VISUAL'] = 'vim'
    cli(['--directory', "#{workdir}"])
    assert_equal('vim', StandupMD.config.cli.editor)

    cli(['--editor', 'mate', '--directory', "#{workdir}"])
    assert_equal('mate', StandupMD.config.cli.editor)
  end

  def test_print
    enable_stdout_redirection

    cli(['--directory', "#{workdir}"])
    refute(StandupMD.config.cli.print)

    cli(['--print', '--directory', "#{workdir}"])
    assert(StandupMD.config.cli.print)
    assert_equal(Date.today, StandupMD.config.cli.date)

    cli([
      '--print',
      '--directory', "#{workdir}",
      '--print', "#{Date.today.prev_day.strftime(StandupMD.config.file.header_date_format)}"
    ])
    assert(StandupMD.config.cli.print)
    assert_equal(Date.today.prev_day, StandupMD.config.cli.date)
  ensure
    disable_stdout_redireaction
  end

  def test_class_print
    enable_stdout_redirection
    entry = StandupMD::Entry.new(
      Date.today,
      ['Current task'],
      ['Previous task'],
      ['Impediment'],
    )
    assert_nothing_raised { cli(@options).print(entry) }
    assert_nothing_raised { cli(@options).print(nil) }
  ensure
    disable_stdout_redireaction
  end
end
