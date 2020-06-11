require_relative '../../test_helper'
require_relative '../../../lib/standup_md'

class TestCliConfig < TestHelper
  def setup
    super
    StandupMD.config.cli.reset
  end

  def test_reset
    StandupMD.config.cli.editor = 'mate'
    assert_equal('mate', StandupMD.config.cli.editor)
    ENV['VISUAL'] = 'vim'
    assert(StandupMD.config.cli.reset)
    assert_equal('vim', StandupMD.config.cli.editor)
  end

  def test_editor
    ENV['VISUAL'] = 'nano'
    StandupMD.config.cli.reset
    assert_equal('nano', StandupMD.config.cli.editor)
    ENV['VISUAL'] = nil
    ENV['EDITOR'] = 'mate'
    StandupMD.config.cli.reset
    assert_equal('mate', StandupMD.config.cli.editor)
    ENV['VISUAL'] = nil
    ENV['EDITOR'] = nil
    StandupMD.config.cli.reset
    assert_equal('vim', StandupMD.config.cli.editor)
    assert_nothing_raised { StandupMD.config.cli.editor = 'mate' }
    assert_equal('mate', StandupMD.config.cli.editor)
  end

  def test_verbose
    refute(StandupMD.config.cli.verbose)
    assert_nothing_raised { StandupMD.config.cli.verbose = true }
    assert(StandupMD.config.cli.verbose)
  end

  def test_edit
    assert(StandupMD.config.cli.edit)
    assert_nothing_raised { StandupMD.config.cli.edit = false }
    refute(StandupMD.config.cli.edit)
  end

  def test_auto_fill_previous
    assert(StandupMD.config.cli.auto_fill_previous)
    assert_nothing_raised { StandupMD.config.cli.auto_fill_previous = false }
    refute(StandupMD.config.cli.auto_fill_previous)
  end

  def test_date
    assert_equal(Date.today, StandupMD.config.cli.date)
    assert_nothing_raised { StandupMD.config.cli.date = Date.today.prev_day }
    assert_equal(Date.today.prev_day, StandupMD.config.cli.date)
  end

  def test_write
    assert(StandupMD.config.cli.write)
    assert_nothing_raised { StandupMD.config.cli.write = false }
    refute(StandupMD.config.cli.write)
  end

  def test_print
    refute(StandupMD.config.cli.print)
    assert_nothing_raised { StandupMD.config.cli.print = true }
    assert(StandupMD.config.cli.print)
  end
end
