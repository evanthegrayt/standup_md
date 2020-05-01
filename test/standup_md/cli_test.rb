require_relative '../../lib/standup_md/cli'
require_relative '../test_helper'

##
# The test suite for +Cli+.
class TestCli < Test::Unit::TestCase
  include TestHelper

  ##
  # Set working directory, current month's file, and last month's file, which
  # will be created and destroyed for each test.
  def setup
    @workdir = File.join(__dir__, 'files')
    @current_test_file =
      File.join(@workdir, Date.today.strftime('%Y_%m.md'))
    @previous_month_test_file =
      File.join(@workdir, Date.today.prev_month.strftime('%Y_%m.md'))
    @options = ['--no-edit', '--no-write', "--directory=#{@workdir}"]
  end

  ##
  # Destroy the working directory and its contents.
  def teardown
    FileUtils.rm_r(@workdir) if File.directory?(@workdir)
    FileUtils.rm(@current_test_file) if File.file?(@current_test_file)
  end

  ##
  # The user's preference file is a string.
  def test_PREFERENCE_FILE
    assert_equal(
      File.expand_path(File.join(ENV['HOME'], '.standup_md.yml')),
      StandupMD::Cli::PREFERENCE_FILE
    )
  end

  ##
  # The +execute+ method is the entry point for the Cli. It's parameter is an
  # array of command-line flags
  def test_self_execute
    assert_nothing_raised { StandupMD::Cli.execute(@options) }
  end

  ##
  # The +options+ should be an array of options passed from the command line.
  def test_options
    c = cli(@options)
    assert_equal(@options, c.options)
  end

  ##
  # The +preferences+ are the settings after +options+ are parsed.
  def test_preferences
    c = cli(@options)
    assert_equal(false, c.instance_variable_get('@write'))
    assert_equal(false, c.instance_variable_get('@edit'))
    assert_equal(@workdir, c.preferences['directory'])
  end

  ##
  # The +initialize+ method should accept the same parameters as +exectute+.
  def test_initialize
    assert_nothing_raised { StandupMD::Cli.new(@options) }
  end

  ##
  # Creates the instance of +StandupMD+.
  def test_standup
    c = cli
    assert_instance_of(StandupMD, c.standup)
  end

  ##
  # The editor should be set by preferences, or env, or set to 'vim'.
  def test_editor
    c = cli
    if ENV['VISUAL']
      assert_equal(ENV['VISUAL'], c.editor)
    elsif ENV['EDITOR']
      assert_equal(ENV['EDITOR'], c.editor)
    else
      assert_equal('vim', c.editor)
    end

    c = cli(['--editor=mate'])
    assert_equal('mate', c.editor)
  end

  ##
  # False by default. True if flag is passed.
  def test_print_current_entry?
    c = cli
    refute(c.print_current_entry?)

    c = cli(['-c'])
    assert(c.print_current_entry?)
  end

  ##
  # False by default. True if flag is passed.
  def test_json?
    c = cli
    refute(c.json?)

    c = cli(['-j'])
    assert(c.json?)
  end

  ##
  # False by default. True if flag is passed.
  def test_print_all_entries?
    c = cli
    refute(c.print_all_entries?)

    c = cli(['-a'])
    assert(c.print_all_entries?)
  end

  ##
  # False by default. True if flag is passed.
  def test_verbose?
    c = cli
    refute(c.verbose?)

    c = cli(['-v'])
    assert(c.verbose?)
  end

  ##
  # True by default. False if flag is passed.
  def test_write?
    c = cli
    assert(c.write?)

    c = cli(['--no-write'])
    refute(c.write?)
  end

  ##
  # True by default. False if flag is passed.
  def test_edit?
    c = cli
    assert(c.edit?)

    c = cli(['--no-edit'])
    refute(c.edit?)
  end

  ##
  # True by default. False if flag is passed.
  def test_append_previous?
    c = cli
    assert(c.append_previous?)

    c = cli(['--no-append-previous'])
    refute(c.append_previous?)
  end

  ##
  # True only if +--no-append+ and +--previous-entry-tasks+ are passed.
  def should_append?
    c = cli
    refute(c.should_append?)

    c = cli['--no-append']
    refute(c.should_append?)

    c = cli(['--no-append', '--previous-entry-tasks="test one","test two"'])
    refute(c.should_append?)

    c = cli(['--previous-entry-tasks="test one","test two"'])
    assert(c.should_append?)
  end
end
